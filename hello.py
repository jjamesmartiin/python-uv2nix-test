import httpx
import sys

def main():
    print("Hello from python-test!")
    print("Testing httpx...", end="")
    sys.stdout.flush()
    r = httpx.get('https://www.example.org/')
    print(r)

if __name__ == "__main__":
    main()
