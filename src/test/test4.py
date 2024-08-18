import requests
import base64


# Read the process_id generated from test1.py
def read_process_id_from_file(process_id_path):
    with open(process_id_path, 'r') as file:
        content = file.read().strip()
        process_id = int(content)
    return process_id


def base64_to_file(encoded_data, output_file_path):
    try:
        decoded_data = base64.b64decode(encoded_data.encode('utf-8'))
        with open(output_file_path, 'wb') as file:
            file.write(decoded_data)
    except Exception as e:
        print(f"Error decoding Base64 to file: {e}")
    

process_id = read_process_id_from_file("process_id.txt")

# Read the message_id generated by test3.py
message_id = ""
with open("message_id.txt", 'r') as file:
        content = file.read().strip()
        message_id = content

# Set the URL to the Flask route
url = "http://localhost:8888//decrypt/"

# Prepare the payload (data) to send in the request
payload = {
    "process_id": str(process_id),
    "message_id": str(message_id),
    # This actor is the MANUFACTURER, the only one that for
    # testing purposes has his RSA public key on blockchain
    "actor": "0x7364cc4E7F136a16a7c38DE7205B7A5b18f17258"
}

# Set the headers to specify that the content type is JSON
headers = {
    "Content-Type": "application/json"
}

# Send the POST request
response = requests.post(url, json=payload, headers=headers)

# Print out the status code and decrypt base64 file
print("Status Code:", response.status_code)
parts = response.text.split('\n', 1)
base64_to_file(parts[1], "file.pdf")
print(f"File decrypted!")