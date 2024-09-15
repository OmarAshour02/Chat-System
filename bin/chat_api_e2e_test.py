import requests
import random
import concurrent.futures
import argparse
import json
import time
from typing import List, Dict
import logging

GREEN = '\033[92m'
RED = '\033[91m'
RESET = '\033[0m'

class ColoredFormatter(logging.Formatter):
    def format(self, record):
        if record.levelno == logging.INFO:
            record.msg = f"{GREEN}{record.msg}{RESET}"
        elif record.levelno == logging.ERROR:
            record.msg = f"{RED}{record.msg}{RESET}"
        return super().format(record)

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
handler = logging.StreamHandler()
handler.setFormatter(ColoredFormatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s'))
logger.addHandler(handler)


logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

BASE_URL = "http://localhost:3000/api/v1"  

def create_application(name: str) -> Dict:
    response = requests.post(f"{BASE_URL}/applications", json={"application": {"name": name}})
    response.raise_for_status()
    logger.info(f"Created application: {response.json()}")
    return response.json()

def create_chat(app_token: str) -> Dict:
    response = requests.post(f"{BASE_URL}/applications/{app_token}/chats")
    response.raise_for_status()
    logger.info(f"Created chat: {response.json()}")
    time.sleep(1)
    return response.json()

def create_message(app_token: str, chat_number: int, body: str) -> Dict:
    url = f"{BASE_URL}/applications/{app_token}/chats/{chat_number}/messages"
    payload = json.dumps({
        "body": body
    })
    headers = {
        'Content-Type': 'application/json'
    }
    logger.info(f"Attempting to create message at URL: {url}")
    logger.info(f"Headers: {headers}")
    logger.info(f"Payload: {payload}")
    
    response = requests.request("POST", url, headers=headers, data=payload)
    logger.info(f"Response status code: {response.status_code}")
    logger.info(f"Response content: {response.text}")
    return response.json()

def get_application(app_token: str) -> Dict:
    response = requests.get(f"{BASE_URL}/applications/{app_token}")
    response.raise_for_status()
    return response.json()

def get_chats(app_token: str) -> List[Dict]:
    response = requests.get(f"{BASE_URL}/applications/{app_token}/chats")
    response.raise_for_status()
    return response.json()

def get_messages(app_token: str, chat_number: int) -> List[Dict]:
    response = requests.get(f"{BASE_URL}/applications/{app_token}/chats/{chat_number}/messages")
    response.raise_for_status()
    return response.json()

def search_messages(app_token: str, chat_number: int, query: str) -> List[Dict]:
    response = requests.get(f"{BASE_URL}/applications/{app_token}/chats/{chat_number}/messages/search", params={"query": query})
    response.raise_for_status()
    return response.json()

def create_app_with_chats_and_messages(app_name: str, num_chats: int, num_messages: int) -> None:
    try:
        app = create_application(app_name)
        app_token = app['token']
        
        for _ in range(num_chats):
            chat = create_chat(app_token)
            chat_number = chat['number']
            
            for _ in range(num_messages):
                message_body = f"Test message {random.randint(1, 1000)}"
                create_message(app_token, chat_number, message_body)
        
        app_info = get_application(app_token)
        assert app_info['name'] == app_name, f"Application name mismatch: {app_info['name']} != {app_name}"
        assert app_info['chats_count'] == num_chats, f"Chats count mismatch: {app_info['chats_count']} != {num_chats}"
        
        chats = get_chats(app_token)
        assert len(chats) == num_chats, f"Number of chats mismatch: {len(chats)} != {num_chats}"
        
        for chat in chats:
            messages = get_messages(app_token, chat['number'])
            assert len(messages) == num_messages, f"Number of messages mismatch: {len(messages)} != {num_messages}"
        
        search_query = "Test message"
        search_results = search_messages(app_token, chats[0]['number'], search_query)
        assert len(search_results) > 0, "Search returned no results"

        logger.info(f"Application {app_name} created and verified successfully.")
    except Exception as e:
        logger.error(f"Error in create_app_with_chats_and_messages: {str(e)}")
        raise

def main(num_apps: int, num_chats: int, num_messages: int, num_threads: int) -> None:
    with concurrent.futures.ThreadPoolExecutor(max_workers=num_threads) as executor:
        futures = []
        for i in range(num_apps):
            app_name = f"TestApp{i+1}"
            futures.append(executor.submit(create_app_with_chats_and_messages, app_name, num_chats, num_messages))
        
        for future in concurrent.futures.as_completed(futures):
            try:
                future.result()
            except Exception as e:
                logger.error(f"An error occurred: {str(e)}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="End-to-end test script for Chat API")
    parser.add_argument("--apps", type=int, help="Number of applications to create")
    parser.add_argument("--chats", type=int, help="Number of chats to create per application")
    parser.add_argument("--messages", type=int, help="Number of messages to create per chat")
    parser.add_argument("--threads", type=int, help="Number of threads to use")
    
    args = parser.parse_args()
    
    num_apps = args.apps or random.randint(1, 5)
    num_chats = args.chats or random.randint(1, 10)
    num_messages = args.messages or random.randint(1, 20)
    num_threads = args.threads or random.randint(1, 5)
    
    logger.info(f"Running test with: {num_apps} apps, {num_chats} chats per app, {num_messages} messages per chat, using {num_threads} threads")
    
    main(num_apps, num_chats, num_messages, num_threads)