import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.List;

public class ParallelFileTransfer {

    public static void main(String[] args) {
        String remoteUser = "user";
        String remoteHost = "host";
        String remoteDirectory = "/remote/path/"; // Remote directory
        String filePattern = "*.txt"; // File pattern
        String localPath = "C:\\local\\path\\";
        String password = "your_password";

        try {
            // List files matching the pattern
            List<String> files = listRemoteFiles(remoteUser, remoteHost, remoteDirectory, filePattern, password);
            if (files != null && !files.isEmpty()) {
                // Download each file in parallel
                for (String file : files) {
                    String remoteFile = remoteDirectory + file; // Correctly construct the remote file path
                    new Thread(() -> {
                        try {
                            transferFile(remoteUser, remoteHost, remoteFile, localPath, password);
                        } catch (IOException e) {
                            e.printStackTrace();
                        }
                    }).start();
                }
            } else {
                System.out.println("No files found matching the pattern.");
            }
        } catch (IOException | InterruptedException e) {
            e.printStackTrace();
        }
    }

    private static List<String> listRemoteFiles(String user, String host, String directory, String pattern, String password) throws IOException, InterruptedException {
        String command = "ls " + directory + pattern;
        System.out.println("Executing command: " + command);

        ProcessBuilder pb = new ProcessBuilder(
            "cmd.exe", "/C",
            "plink", "-batch", "-pw", password,
            user + "@" + host,
            command
        );
        Process process = pb.start();
        int exitCode = process.waitFor();

        if (exitCode != 0) {
            System.err.println("Command failed with exit code: " + exitCode);
            return new ArrayList<>();
        }

        BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
        String line;
        List<String> files = new ArrayList<>();
        while ((line = reader.readLine()) != null) {
            System.out.println("Found file: " + line.trim()); // Debugging output
            files.add(line.trim());
        }

        return files;
    }

    private static void transferFile(String user, String host, String remoteFile, String localPath, String password) throws IOException {
        // Construct the remote path with user and host
        String remotePath = user + "@" + host + ":" + remoteFile;
        System.out.println("Transferring file: " + remotePath + " to local path: " + localPath);

        ProcessBuilder pb = new ProcessBuilder(
            "cmd.exe", "/C",
            "pscp", "-batch", "-C", // Use compression
            "-pw", password,
            remotePath, localPath
        );
        Process process = pb.start();

        // Capture and print output and error streams
        BufferedReader stdOutput = new BufferedReader(new InputStreamReader(process.getInputStream()));
        BufferedReader stdError = new BufferedReader(new InputStreamReader(process.getErrorStream()));

        String s;
        while ((s = stdOutput.readLine()) != null) {
            System.out.println(s);
        }
        while ((s = stdError.readLine()) != null) {
            System.err.println(s);
        }

        try {
            int exitCode = process.waitFor();
            if (exitCode != 0) {
                System.err.println("Transfer failed for: " + remotePath + " with exit code " + exitCode);
            } else {
                System.out.println("Transfer successful for: " + remotePath);
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            e.printStackTrace();
        }
    }
}