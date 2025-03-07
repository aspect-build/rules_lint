import java.io.FileInputStream;
import java.io.IOException;

public class FileReaderUtil {

  public void readFile(String fileName) throws IOException {
    try (FileInputStream fis = new FileInputStream(fileName)) {
      // Process the file input stream
      System.out.println("File read successfully");
    }
  }
}
