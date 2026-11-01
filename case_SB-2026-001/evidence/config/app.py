from flask import Flask, render_template, request, session, redirect, url_for
import mysql.connector
import logging
import os
from datetime import datetime

app = Flask(__name__)
app.secret_key = 'insecure_secret_key_123'

# Configure logging
logging.basicConfig(
    filename='/app/evidence/securebank.log',
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

def get_db_connection():
    """Vulnerable database connection - intentionally insecure"""
    return mysql.connector.connect(
        host=os.getenv('MYSQL_HOST', 'mysql'),
        user=os.getenv('MYSQL_USER', 'admin'),
        password=os.getenv('MYSQL_PASSWORD', 'password'),
        database=os.getenv('MYSQL_DB', 'securebank')
    )

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/login', methods=['POST'])
def login():
    username = request.form.get('username', '')
    password = request.form.get('password', '')
    
    # VULNERABILITY 1: SQL Injection
    query = f"SELECT * FROM users WHERE username = '{username}' AND password = '{password}'"
    
    logging.info(f"LOGIN_ATTEMPT username={username} ip={request.remote_addr}")
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute(query)  # Vulnerable!
        user = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if user:
            session['user'] = username
            logging.info(f"LOGIN_SUCCESS username={username}")
            return f"Welcome {username}! <br><a href='/accounts'>View Accounts</a>"
        else:
            logging.warning(f"LOGIN_FAILED username={username}")
            return "Login failed. <a href='/'>Try again</a>"
    except Exception as e:
        logging.error(f"LOGIN_ERROR: {str(e)}")
        return f"Error: {str(e)}"

@app.route('/accounts')
def accounts():
    if 'user' not in session:
        return redirect('/')
    
    # VULNERABILITY 2: Command Injection (simulated)
    account_id = request.args.get('id', '1')
    
    # Vulnerable command construction
    cmd = f"echo 'Processing account {account_id}'"
    result = os.popen(cmd).read()  # Vulnerable!
    
    # Simulate account data
    accounts = [
        {'id': 1, 'type': 'Savings', 'balance': '$10,000'},
        {'id': 2, 'type': 'Checking', 'balance': '$5,000'},
        {'id': 3, 'type': 'Investment', 'balance': '$50,000'}
    ]
    
    logging.info(f"ACCOUNT_VIEW user={session['user']} account_id={account_id}")
    
    return render_template('accounts.html', 
                         user=session['user'], 
                         accounts=accounts,
                         command_result=result)

@app.route('/search')
def search():
    # VULNERABILITY 3: Reflected XSS
    query = request.args.get('q', '')
    
    # Vulnerable - directly reflects user input
    return f"Search results for: {query}<br><a href='/'>Back</a>"

@app.route('/transfer', methods=['POST'])
def transfer():
    if 'user' not in session:
        return redirect('/')
    
    amount = request.form.get('amount', '')
    to_account = request.form.get('to_account', '')
    
    # Log transfer attempt
    logging.info(f"TRANSFER_ATTEMPT from={session['user']} to={to_account} amount={amount}")
    
    return f"Transfer of ${amount} to account {to_account} initiated.<br><a href='/accounts'>Back to Accounts</a>"

@app.route('/logs')
def view_logs():
    # Endpoint to view logs (for forensic analysis)
    try:
        with open('/app/evidence/securebank.log', 'r') as f:
            logs = f.read()
        return f"<pre>{logs}</pre><br><a href='/'>Back</a>"
    except:
        return "No logs found"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)  # debug=True is also a vulnerability
