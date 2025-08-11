package com.mypos.smartsdk.print;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.util.Base64;

import com.google.gson.annotations.SerializedName;

import java.io.ByteArrayOutputStream;

/**
 *
 */

public class PrinterCommand {

    public enum CommandType {
        /**
         * If type is header, the text should contain the receipt date in format "DD/MM/YY;HH:mm:ss"!
         */
        @SerializedName("HEADER")
        HEADER,
        @SerializedName("LOGO")
        LOGO,
        @SerializedName("TEXT")
        TEXT,
        @SerializedName("FOOTER")
        FOOTER,
        @SerializedName("IMAGE")
        IMAGE
    }

    public enum Alignment {
        @SerializedName("ALIGN_LEFT")
        ALIGN_LEFT,
        @SerializedName("ALIGN_CENTER")
        ALIGN_CENTER,
        @SerializedName("ALIGN_RIGHT")
        ALIGN_RIGHT,
    }

    public static final int     RECEIPT_SMART_MAX_CHARS_PER_LINE = 32;
    public static final int     RECEIPT_HUB_MAX_CHARS_PER_LINE   = 39;

    /**
     * The command's type
     */
    @SerializedName("type")
    private CommandType type;
    /**
     * The text to be printed
     */
    @SerializedName("text")
    private String text;
    /**
     * Should the text be printed with double width?
     */
    @SerializedName("doubleWidth")
    private boolean doubleWidth;
    /**
     * Should the text be printed with double height?
     */
    @SerializedName("doubleHeight")
    private boolean doubleHeight;
    /**
     * The encoding
     */
    @SerializedName("encoding")
    private String  encoding;
    /**
     * Image to be printed
     */
    @SerializedName("imageEncoded")
    private String imageEncoded;
    /**
     * Font size
     */
    @SerializedName("fontSize")
    private int fontSize;
    /**
     * Alignment of the text.
     */
    @SerializedName("alignment")
    private Alignment alignment = Alignment.ALIGN_LEFT;


    public PrinterCommand(CommandType type) {
        this.type = type;

        if (type == CommandType.TEXT) {
            text = " ";
        }
    }

    public PrinterCommand(String text) {
        this.type = CommandType.TEXT;
        this.text = text;
    }

    public PrinterCommand(CommandType type, String text) {
        this.type = type;
        this.text = text;
    }

    @Deprecated
    public PrinterCommand(String text, String encoding) {
        this.text = text;
        this.encoding = encoding;
    }

    @Deprecated
    public PrinterCommand(String text, boolean doubleWidth, boolean doubleHeight) {
        this.text = text;
        this.doubleWidth = doubleWidth;
        this.doubleHeight = doubleHeight;
    }

    @Deprecated
    public PrinterCommand(CommandType type, String text, boolean doubleWidth, boolean doubleHeight) {
        this.type = type;
        this.text = text;
        this.doubleWidth = doubleWidth;
        this.doubleHeight = doubleHeight;
    }

    public PrinterCommand(CommandType type, Bitmap image) {
        this.type = type;
        setImage(image);
    }

    public PrinterCommand(String text, int fontSize) {
        this.type = CommandType.TEXT;
        this.text = text;
        this.fontSize = fontSize;
    }

    public PrinterCommand(CommandType type, String text, int fontSize) {
        this.type = type;
        this.text = text;
        this.fontSize = fontSize;
    }

    public PrinterCommand(String text, Alignment alignment) {
        this.type = CommandType.TEXT;
        this.text = text;
        this.alignment = alignment;
    }

    public PrinterCommand(CommandType type, String text, Alignment alignment) {
        this.type = type;
        this.text = text;
        this.alignment = alignment;
    }

    public PrinterCommand(String text, int fontSize, Alignment alignment) {
        this.type = CommandType.TEXT;
        this.text = text;
        this.fontSize = fontSize;
        this.alignment = alignment;
    }

    public PrinterCommand(CommandType type, String text, int fontSize, Alignment alignment) {
        this.type = type;
        this.text = text;
        this.fontSize = fontSize;
        this.alignment = alignment;
    }

    public PrinterCommand(CommandType type, String leftText, String rightText) {
        this.type = type;
        this.text = formatRow(leftText, rightText, RECEIPT_SMART_MAX_CHARS_PER_LINE);
    }


    public PrinterCommand(CommandType type, String leftText, String rightText, int maxCharsPerLine) {
        this.type = type;
        this.text = formatRow(leftText, rightText, maxCharsPerLine);
    }

    public String getText() {
        return text;
    }

    public PrinterCommand setText(String text) {
        this.text = text;
        return this;
    }

    @Deprecated
    public boolean isDoubleWidth() {
        return doubleWidth;
    }

    @Deprecated
    public PrinterCommand setDoubleWidth(boolean doubleWidth) {
        this.doubleWidth = doubleWidth;
        return this;
    }

    public boolean isDoubleHeight() {
        return doubleHeight;
    }

    public PrinterCommand setDoubleHeight(boolean doubleHeight) {
        this.doubleHeight = doubleHeight;
        return this;
    }

    @Deprecated
    public String getEncoding() {
        return encoding;
    }

    @Deprecated
    public PrinterCommand setEncoding(String encoding) {
        this.encoding = encoding;
        return this;
    }

    public CommandType getType() {
        return type;
    }

    public PrinterCommand setType(CommandType type) {
        this.type = type;
        return this;
    }

    public int getFontSize() {
        return fontSize;
    }

    public PrinterCommand setFontSize(int fontSize) {
        this.fontSize = fontSize;
        return this;
    }

    public Alignment getAlignment() {
        return alignment;
    }

    public PrinterCommand setAlignment(Alignment alignment) {
        this.alignment = alignment;
        return this;
    }

    public Bitmap getImage() {
        byte[] decodedString = Base64.decode(this.imageEncoded, Base64.DEFAULT);
        Bitmap decodedByte = BitmapFactory.decodeByteArray(decodedString, 0, decodedString.length);
        return decodedByte;
    }

    public PrinterCommand setImage(Bitmap image) {
        final int COMPRESSION_QUALITY = 100;
        ByteArrayOutputStream byteArrayBitmapStream = new ByteArrayOutputStream();

        image.compress(Bitmap.CompressFormat.PNG, COMPRESSION_QUALITY, byteArrayBitmapStream);
        byte[] b = byteArrayBitmapStream.toByteArray();
        this.imageEncoded = Base64.encodeToString(b, Base64.DEFAULT);

        return this;
    }

    public static String columnRow(String[] texts, int[] weights, Alignment[] alignments, String separator, int maxCharsPerLine) {
        StringBuilder result = new StringBuilder();
        int i = 0;
        int maxWeight = 0;
        int indexOfFirstSpace = -1;
        String[] textsLineTwo = null;
        int maxCharsPerLineCopy = maxCharsPerLine;

        if (separator == null)
            separator = "";

        for (i = 0; i < weights.length; i++) {
            maxWeight += weights[i];
        }

        maxCharsPerLineCopy -= separator.length() * (texts.length - 1);

        double charsPerWeight = maxCharsPerLineCopy / maxWeight;

        for (i = 0 ; i < texts.length; i++) {
            String text = texts[i];

            if (text == null)
                text = "";

            int spacesCount = (int) Math.round(weights[i] * charsPerWeight - text.length());

            if (spacesCount < 0) {
                if (textsLineTwo == null)
                    textsLineTwo = new String[texts.length];

                textsLineTwo[i] = text.substring(text.length() + spacesCount);
                text = text.substring(0, text.length() + spacesCount);
            }

            String spaces = spaces(spacesCount);

            if (alignments[i] == Alignment.ALIGN_LEFT) {
                result.append(text).append(spaces);

                if (indexOfFirstSpace < 0 && spaces.length() > 0)
                    indexOfFirstSpace = text.length();
            }
            else if (alignments[i] == Alignment.ALIGN_CENTER) {
                result.append(spaces.substring(0, spaces.length() / 2)).append(text).append(spaces.substring(spaces.length() / 2));

                if (indexOfFirstSpace < 0 && spaces.length() > 1)
                    indexOfFirstSpace = 0;
            }
            else if (alignments[i] == Alignment.ALIGN_RIGHT) {
                result.append(spaces).append(text);

                if (indexOfFirstSpace < 0 && spaces.length() > 0)
                    indexOfFirstSpace = 0;
            }

            if (i < texts.length - 1)
                result.append(separator);
        }

        while (result.length() > maxCharsPerLine) {
            int index;

            if (indexOfFirstSpace >= 0 && result.charAt(indexOfFirstSpace) == ' ')
                index = indexOfFirstSpace;
            else
                index = result.indexOf(" ");

            if (index < 0)
                index = 0;

            result.deleteCharAt(index);
        }

        while (result.length() < maxCharsPerLine) {
            int index;

            if (indexOfFirstSpace >= 0)
                index = indexOfFirstSpace;
            else
                index = result.indexOf(" ");

            if (index < 0)
                index = 0;

            result.insert(index, " ");
        }

        if (textsLineTwo != null)
            result.append(columnRow(textsLineTwo, weights, alignments, separator, maxCharsPerLine));

        return result.toString();
    }

    private static String spaces(int number) {
        StringBuilder result = new StringBuilder();
        for (int i = 0; i < number; i++)
            result.append(" ");

        return result.toString();
    }

    private static String formatRow(String leftText, String rightText, int maxCharsPerLine){
        String formattedRow = "";

        if (leftText == null)
            leftText = "";

        if (rightText == null)
            rightText = "";

        if(leftText.length() + rightText.length() <= maxCharsPerLine){
            formattedRow = leftText;
            while (formattedRow.length() + rightText.length() < maxCharsPerLine){
                formattedRow += " ";
            }
            formattedRow += rightText;
        }
        else{
            maxCharsPerLine = maxCharsPerLine - 1;
            float ratio = (float) leftText.length() / (float) (leftText.length() + rightText.length());
            int charsForLeft = Math.round(ratio * maxCharsPerLine);

            if (charsForLeft < 4)
                charsForLeft = Math.min(4, leftText.length());
            else
            if (charsForLeft > maxCharsPerLine - 4)
                charsForLeft = maxCharsPerLine - Math.min(4, rightText.length());

            while (!leftText.isEmpty() || !rightText.isEmpty()) {
                leftText = leftText.trim();
                rightText = rightText.trim();

                boolean notEnoughFromLeft = leftText.length() < charsForLeft;
                boolean notEnoughFromRight = rightText.length() < maxCharsPerLine - charsForLeft;

                if (notEnoughFromLeft)
                    while (leftText.length() < charsForLeft)
                        leftText = String.format("%s ", leftText);

                if (notEnoughFromRight)
                    while (rightText.length() < maxCharsPerLine - charsForLeft)
                        rightText = String.format(" %s", rightText);

                formattedRow += String.format("%s %s\n", leftText.substring(0, charsForLeft), rightText.substring(0,  maxCharsPerLine - charsForLeft));

                leftText = leftText.substring(charsForLeft);
                rightText = rightText.substring( maxCharsPerLine - charsForLeft);
            }
        }
        return formattedRow;
    }
}
