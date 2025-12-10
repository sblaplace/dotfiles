import os
import requests
import json
from datetime import datetime, timedelta

LUNCH_MONEY_TOKEN = os.environ.get("LUNCH_MONEY_TOKEN")
SLACK_WEBHOOK = os.environ.get("SLACK_WEBHOOK")
CACHE_FILE = "state/processed_ids.json" # Keeping JSON for simplicity of set serialization

def load_processed_ids():
    if os.path.exists(CACHE_FILE):
        try:
            with open(CACHE_FILE, 'r') as f:
                return set(json.load(f))
        except:
            return set()
    return set()

def save_processed_ids(ids):
    os.makedirs("state", exist_ok=True)
    with open(CACHE_FILE, 'w') as f:
        # Sort for deterministic diffs if you ever commit it
        json.dump(sorted(list(ids)), f)

def get_transactions():
    # 3 day window is the "danger zone" for dupes
    start_date = (datetime.now() - timedelta(days=3)).strftime('%Y-%m-%d')
    url = "https://dev.lunchmoney.app/v1/transactions"
    headers = {"Authorization": f"Bearer {LUNCH_MONEY_TOKEN}"}
    params = {"start_date": start_date} 
    resp = requests.get(url, headers=headers, params=params)
    return resp.json().get('transactions', [])

def post_to_slack(tx):
    amt = float(tx['amount'])
    icon = ":chart_with_upwards_trend:" if amt > 0 else ":money_with_wings:"
    payload = {
        "blocks": [
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"{icon} *{tx['payee']}*\n`${amt:.2f}`  |  _{tx['date']}_"
                }
            }
        ]
    }
    requests.post(SLACK_WEBHOOK, json=payload)

if __name__ == "__main__":
    # 1. Load what we knew about last time
    known_ids = load_processed_ids()
    
    # 2. Fetch what exists now
    current_txs = get_transactions()
    current_ids_set = {tx['id'] for tx in current_txs}
    
    # 3. Process new stuff
    for tx in current_txs:
        if tx['id'] not in known_ids:
            print(f"New transaction: {tx['payee']}")
            post_to_slack(tx)
            
    # 4. Save State
    # Crucial Optimization: We only need to remember IDs that are currently visible.
    # If an ID is in 'known_ids' but NOT in 'current_ids_set', it means it has 
    # fallen out of the 3-day window. We can forget it.
    # The new state is simply the set of ALL currently visible IDs.
    
    save_processed_ids(current_ids_set)

