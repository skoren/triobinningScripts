import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.InputStreamReader;
import java.text.DecimalFormat;
import java.text.NumberFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;

public class SubFasta {  
  private static final NumberFormat nf = new DecimalFormat("############.#");

  private static final String[] fastaEnds = {"bases", "qv", "qual", "fna", "contig", "fa", "fasta"};   
  private static final String[] fastqEnds = {"fq", "fastq", "txt"};
  private static class Position {
      public int start;
      public int end;
      public String name = null;
 
      public Position() {
      }

      public Position(int s, int e, String n) {
         start = s;
         end = e;
         name = n;
      }
   }

   private static final int MAX_READ = 10000;

   private HashMap<Integer, ArrayList<Double>> positionQual = new HashMap<Integer, ArrayList<Double>>(MAX_READ);
   private HashMap<String, ArrayList<Position>> fastaToOutput = new HashMap<String, ArrayList<Position>>();
   private HashMap<String, Integer> outputToPosition = new HashMap<String, Integer>();
   private HashMap<String, Boolean> outputIDs = new HashMap<String, Boolean>();
   private int minValue = Integer.MAX_VALUE;
   private int maxValue = Integer.MIN_VALUE;
   private boolean splitByTab = false; 
   private boolean reorder = false;

   private ArrayList<String> toOutput = new ArrayList<String>();

   public SubFasta() {
   }

   public void inputIDs(String file) throws Exception {
      if (file == null || file.equalsIgnoreCase("null")) {
         return;
      }
      String line = null;
      BufferedReader bf = new BufferedReader(new InputStreamReader(
            new FileInputStream(file)));
      int position = 0;
      while ((line = bf.readLine()) != null) {
         String[] split = null;

         if (splitByTab == true) {
            split=line.trim().split("\\t+");
         } else {
            split=line.trim().split("\\s+");
         }

         try {
            if (split.length < 3) {
               throw new Exception("Insufficient number of arguments");
            }
            Position p = new Position();
            p.start = Integer.parseInt(split[1])-1;
            p.end = Integer.parseInt(split[2])-1;

            if (split.length > 3) {
              p.name = split[3];
            }
            if (fastaToOutput.get(split[0]) == null) {
               fastaToOutput.put(split[0], new ArrayList<Position>());
            }
            fastaToOutput.get(split[0]).add(p);
            outputToPosition.put(split[0], position);
            position++;
         } catch (Exception e) {
           System.err.println("Invalid line " + e.getLocalizedMessage() + " for line " + line);
         }
      }
      bf.close();
   }

   public void outputFasta(String fastaSeq, String ID) {
      boolean isInN = true;
      int lastPos = fastaSeq.length();
      for (int i = 0; i < fastaSeq.length(); i++) {
         if (fastaSeq.charAt(i) == 'N') {
            if (isInN == false) { lastPos = i; }
            isInN = true;
          } else {
            isInN = false;
          }
      }
      if (isInN == true) {
         System.err.println("Trimming sequence " + ID + " to be " + lastPos + " instead of " + fastaSeq.length());
      } else {
         lastPos = fastaSeq.length();
      }
      outputFasta(fastaSeq.substring(0, lastPos).toUpperCase(), null, ID, ">", null, true);
   }

   public void outputFasta(String fastaSeq, String qualSeq, String ID, String fastaSeparator, String qualSeparator, boolean convert) {
      if (fastaSeq.length() == 0) {
         return;
      }

      if (qualSeq != null && qualSeq.length() != fastaSeq.length()) {
         System.err.println("Error length of sequences and fasta for id " + ID + " aren't equal fasta: " + fastaSeq.length() + " qual: " + qualSeq.length());
         qualSeq = qualSeq.substring(0, Math.min(qualSeq.length(), fastaSeq.length()));
         //System.exit(1);
      }
      String IDtoCheck=(splitByTab == true ? ID : ID.split("\\s+")[0]);

      if (fastaToOutput.size() == 0 || fastaToOutput.get(IDtoCheck) != null) {
         if (outputIDs.get(ID) != null && outputIDs.get(ID) == true) {
            return;
         }

         StringBuilder str = new StringBuilder();
         
         boolean rc = false;
         String origID = IDtoCheck;
         outputIDs.put(ID, true);
         ArrayList<Position> ps = fastaToOutput.get(IDtoCheck);
         for (Position p : ps) {
            if (p == null) { p = new Position(0, 0, ID); }
            if (p.start > p.end) { rc = true; int tmp = p.start; p.start = p.end; p.end = tmp; }
            if (p.start < 0) { p.start = 0; }
            if (p.end == 0 || p.end > fastaSeq.length()) { System.err.println("FOR ID " + ID + " ADJUSTED END to " + fastaSeq.length()); p.end = fastaSeq.length(); }
            if (ID.indexOf(",") != -1) { ID = ID.split(",")[0]; }
            if (p.name != null && p.name.indexOf(",") != -1) { p.name = p.name.split(",")[0]; }

            if (reorder) {
               str.append(fastaSeparator + (p.name == null ? ID : p.name) + "\n");
            } else { 
               System.out.println(fastaSeparator + (p.name == null ? ID : p.name));
            }
            String toPrint = fastaSeq.substring(p.start, (Math.min(p.end+1, fastaSeq.length()))).toUpperCase();
            if (rc) {
               toPrint = Utils.rc(toPrint);
            }
            if (reorder) {
                str.append(convert == true ? Utils.convertToFasta(toPrint) : toPrint + "\n");
            } else {
               System.out.println(convert == true ? Utils.convertToFasta(toPrint) : toPrint);
            }
            if (qualSeq != null) {
               if (reorder) {
                  str.append(qualSeparator + (p.name == null ? ID : p.name) + "\n");
                  str.append((convert == true ? Utils.convertToFasta(qualSeq.substring(p.start, Math.min(p.end+1, qualSeq.length()))) : qualSeq.substring(p.start, Math.min(p.end+1, qualSeq.length()))) + "\n");
               } else {
                  System.out.println(qualSeparator + (p.name == null ? ID : p.name));
                  System.out.println((convert == true ? Utils.convertToFasta(qualSeq.substring(p.start, Math.min(p.end+1, qualSeq.length()))) : qualSeq.substring(p.start, Math.min(p.end+1, qualSeq.length()))));
              }
            }
/*
System.err.println(">" + ID);
for (int i = 0; i < qualSeq.length(); i++) {
int value = (int) qualSeq.charAt(i);
if (value < minValue) {
minValue = value;
}
if (value > maxValue) {
maxValue = value;
}

double qv = (double)value;
qv -= (int)'!';
System.err.print(qv + " ");
// store the list of values
if (positionQual.get(i) == null) {
positionQual.put(i, new ArrayList<Double>());
}
positionQual.get(i).add(qv);
}
System.err.println();
*/
         }

         while (toOutput.size() <= outputToPosition.get(origID)) {
            toOutput.add("");
         }
         toOutput.set(outputToPosition.get(origID), str.toString());
      }
   }
 
   public void processFasta(String inputFile) throws Exception {
      BufferedReader bf = Utils.getFile(inputFile, fastaEnds);
      
      String line = null;
      StringBuffer fastaSeq = new StringBuffer();
      String header = "";
StringBuffer qualSeq = new StringBuffer();
      
      while ((line = bf.readLine()) != null) {
         if (line.startsWith(">")) {
            outputFasta(fastaSeq.toString(), header);
/*
         for (int i = 0; i < fastaSeq.length(); i++) {
             qualSeq.append("I");
          } outputFasta(fastaSeq.toString(), qualSeq.toString(), header, "@", "+", false);
*/
            header = line.trim().split("\\s+")[0].substring(1);
            //if (header.indexOf(",") != -1) { header = header.split(",")[0]; }
            fastaSeq = new StringBuffer();
            qualSeq = new StringBuffer();
         }
         else {
if (inputFile.contains("qual") || line.trim().split("\\s+").length > 1) { fastaSeq.append(" "); }
            fastaSeq.append(line);
         }
      }

      outputFasta(fastaSeq.toString(), header);
/*
         for (int i = 0; i < fastaSeq.length(); i++) {
             qualSeq.append("I");
      }
      outputFasta(fastaSeq.toString(), qualSeq.toString(), header, "@", "+", false);
*/

      bf.close();
   }

   public void processFastq(String inputFile) throws Exception {
      BufferedReader bf = Utils.getFile(inputFile, fastqEnds);

      String line = null;
      String header = "";

      while ((line = bf.readLine()) != null) {
         // read four lines at a time for fasta, qual, and headers
         String ID = line.substring(1);
         String fasta = bf.readLine();
         String qualID = bf.readLine().split("\\s+")[0].substring(1);

         if (qualID.length() != 0 && !qualID.equals(ID)) {
            System.err.println("Error ID " + ID + " DOES not match quality ID " + qualID);
            System.exit(1);
         }
         String qualSeq = bf.readLine();
         //outputFasta(fasta, ID);
         outputFasta(fasta, qualSeq, ID, "@", "+", false);
      }

      bf.close();
   }

   public void finish() throws Exception {
      if (reorder == true) {
         for (String out : toOutput) {
            System.out.print(out);
         }
      }
   }

   public static void printUsage() {
      System.err.println("This program subsets a fasta or fastq file by a specified list. The default sequence is N. Multiple fasta files can be supplied by using a comma-separated list.");
      System.err.println("Example usage: SubFasta subsetFile fasta1.fasta,fasta2.fasta");
   }
   
   public static void main(String[] args) throws Exception {     
      if (args.length < 1) { printUsage(); System.exit(1);}

      SubFasta f = new SubFasta();
      if (args.length < 2) {
         printUsage();
         System.exit(1);
      }
      int argOffset = 0;

      if (args[0].equalsIgnoreCase("true") || args[0].equalsIgnoreCase("false")) {
         f.splitByTab = Boolean.parseBoolean(args[0]);
System.err.println ("Splitting using boolean is " + f.splitByTab);
         argOffset++;
      }
      if (args[0].equalsIgnoreCase("-r")) {
         f.reorder = Boolean.parseBoolean(args[1]);
         argOffset++;
         argOffset++;
      }

      f.inputIDs(args[argOffset++]);
      for (int i = argOffset; i < args.length; i++) {
      String[] splitLine = args[i].trim().split(",");
      for (int j = 0; j < splitLine.length; j++) {
System.err.println("Processing file " + splitLine[j]);
     	  if ((splitLine[j].contains("qual") || splitLine[j].contains("qv") || splitLine[j].contains("fasta") || splitLine[j].contains("fna") || splitLine[j].contains("fa") || splitLine[j].contains("contig") || splitLine[j].contains("txt")) && !(splitLine[j].contains("fastq"))) {
             f.processFasta(splitLine[j]);
          } else if (splitLine[j].contains("fastq") || splitLine[j].contains("txt") || splitLine[j].contains("fq")) {
             f.processFastq(splitLine[j]);
          } else {
             System.err.println("Unknown file type " + splitLine[j]);
          }
       }
      }

      f.finish();
/*
      if (f.minValue != Integer.MAX_VALUE) {
         System.err.println("Processed files and min value for quality I saw is " + f.minValue + " aka " + (char)f.minValue + " and max is " + f.maxValue + " AKA " + (char)f.maxValue);
      }

      for (int i = 0; i < MAX_READ; i++) {
         if (f.positionQual.get(i) == null) {
            System.err.println(i + " 0");
         } else {
            double total = 0;
            for (Double val : f.positionQual.get(i)) {
               total+=val;
            }
            total /= f.positionQual.get(i).size();
            System.err.println(i + " " + total);
        }
      }
*/
   }
}
