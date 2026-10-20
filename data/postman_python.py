import requests

url = "https://icanhazdadjoke.com/"
headers = {"Accept": "application/json"}

response = requests.get(url, headers=headers)
print(response.status_code)
print(response.json())
