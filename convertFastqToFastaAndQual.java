import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.InputStreamReader;
import java.text.DecimalFormat;
import java.text.NumberFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.io.File;
import java.io.PrintStream;
import java.util.HashMap;

public class convertFastqToFastaAndQual {  
  private static final NumberFormat nf = new DecimalFormat("############.#");
   
   private static final String[] FASTQ_ENDS = {"fastq", "fq", "txt"};
   private static char OFFSET = '!';

   public convertFastqToFastaAndQual() {
   }

   public void processFastq(String inputFile, String fastaOut, String qualOut, boolean outputQuals) throws Exception {
      BufferedReader bf = Utils.getFile(inputFile, FASTQ_ENDS);
      PrintStream fastaFile = new PrintStream(new File(fastaOut));
      PrintStream qualFile = null;

      if (outputQuals)
         qualFile = new PrintStream(new File(qualOut));

      String line = null;
      String header = "";

      while ((line = bf.readLine()) != null) {
         // read four lines at a time for fasta, qual, and headers
         String ID = line.trim().replaceAll("\\s+", "_").split("\\s+")[0].substring(1);
         String fasta = bf.readLine();
         String qualID = bf.readLine().split("\\s+")[0].substring(1);

         if (qualID.length() != 0 && !qualID.equals(ID) && outputQuals) {
            System.err.println("Error ID " + ID + " DOES not match quality ID " + qualID);
            //System.exit(1);
         }

         String qualSeq = bf.readLine();
         if (qualSeq.length() != fasta.length()) {
            System.err.println(fasta + " and qual " + qualSeq);
            System.err.println("Error sequence " + ID + " length " + fasta.length() + " DOESNT match qv length " + qualSeq.length());
            qualSeq = qualSeq.substring(0, Math.min(qualSeq.length(), fasta.length()));
         }

         StringBuffer decodedQual = null;
         if (outputQuals) {
            decodedQual = new StringBuffer();
            for (int i = 0; i < qualSeq.length(); i++) {
               decodedQual.append((int)qualSeq.charAt(i) - (int)OFFSET);
               decodedQual.append(" ");
            }
         }
         outputFasta(fasta, (decodedQual == null ? null : decodedQual.toString().trim()), ID, ">", ">", true, fastaFile, qualFile);
      }

      bf.close();
   }

   public void outputFasta(String fastaSeq, String qualSeq, String ID, String fastaSeparator, String qualSeparator, boolean convert, PrintStream fastaOut, PrintStream qualOut) {
      if (fastaSeq.length() == 0) {
         return;
      }

         fastaOut.println(fastaSeparator + ID);
         fastaOut.println((convert == true ? Utils.convertToFasta(fastaSeq) : fastaSeq));

         if (qualSeq != null) {
            qualOut.println(qualSeparator + ID);
            qualOut.println((convert == true ? Utils.convertToFasta(qualSeq) : qualSeq));
         }
      }

   public static void printUsage() {
      System.err.println("This program sizes a fasta or fastq file. Multiple fasta files can be supplied by using a comma-separated list.");
      System.err.println("Example usage: convertFastqToFastaAndQual fasta1.fasta,fasta2.fasta");
   }
   
   public static void main(String[] args) throws Exception {     
      if (args.length < 3) { printUsage(); System.exit(1);}

      if (args.length > 3) { 
         if (args[3].equalsIgnoreCase("PHRED64")) {
            OFFSET = '@';
         } else if (args[3].equalsIgnoreCase("PHRED32")) {
            OFFSET = '!';
         }
      }
      boolean outputQual = true;
      if (args.length > 4) {
         outputQual = Boolean.parseBoolean(args[4]);
      }
      convertFastqToFastaAndQual f = new convertFastqToFastaAndQual();

      f.processFastq(args[0], args[1], args[2], outputQual);
   }
}
