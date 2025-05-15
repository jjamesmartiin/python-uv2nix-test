import httpx

def main():
    print("Hello from python-test!")
    r = httpx.get('https://www.example.org/')
    print(r.text)


if __name__ == "__main__":
    main()
