package cordova.plugin.rfidconnector;

public class ConversionUtil {
    private ConversionUtil() {

    }

    public static String hexToAscii(String hexStr) {
        StringBuilder output = new StringBuilder();

        for (int i = 0; i < hexStr.length(); i += 2) {
            String str = hexStr.substring(i, i + 2);
            output.append((char) Integer.parseInt(str, 16));
        }

        return output.toString();
    }

    public static String asciiToHex(String asciiStr) {
        char[] chars = asciiStr.toCharArray();
        StringBuilder hex = new StringBuilder();
        for (char ch : chars) {
            hex.append(Integer.toHexString(ch));
        }

        return hex.toString();
    }

    // public static void main(String[] args) {
    // System.out.println(hexToAscii("4142434430303239"));
    // System.out.println(asciiToHex("ABCD0029"));
    // }
}
