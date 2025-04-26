import threading
import requests
import time

# Configuration (ONLY USE ON AUTHORIZED TARGETS)
TARGET_URL = "http://192.168.1.100"  # Replace with target IP (must be authorized)
THREADS = 50                          # Number of concurrent threads
REQUESTS_PER_THREAD = 100             # Requests per thread
DELAY_BETWEEN_REQUESTS = 0.1          # Delay in seconds

def send_requests():
    try:
        for _ in range(REQUESTS_PER_THREAD):
            response = requests.get(TARGET_URL)
            print(f"Sent request, status: {response.status_code}")
            time.sleep(DELAY_BETWEEN_REQUESTS)
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    print(f"[!] Starting load test on {TARGET_URL} (Authorized Testing Only)")
    print(f"[!] Using {THREADS} threads with {REQUESTS_PER_THREAD} requests each")
    
    threads = []
    for _ in range(THREADS):
        thread = threading.Thread(target=send_requests)
        thread.start()
        threads.append(thread)
    
    for thread in threads:
        thread.join()
    
    print("[!] Load test completed.")
