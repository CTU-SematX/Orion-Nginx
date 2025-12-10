#!/usr/bin/env python3
"""
JWT Token Generator for Orion-LD Gateway
Usage: python3 generate-jwt.py [--secret SECRET] [--user USERNAME] [--hours HOURS]
"""

import jwt
import datetime
import argparse
import os

def generate_jwt_token(secret, username="admin", hours=24):
    """Generate a JWT token"""
    payload = {
        "sub": username,
        "name": f"User {username}",
        "iat": datetime.datetime.now(datetime.UTC),
        "exp": datetime.datetime.now(datetime.UTC) + datetime.timedelta(hours=hours),
        "roles": ["admin", "user"]
    }
    
    token = jwt.encode(payload, secret, algorithm="HS256")
    return token

def main():
    parser = argparse.ArgumentParser(description='Generate JWT token for Orion-LD Gateway')
    parser.add_argument('--secret', default=os.getenv('JWT_SECRET', 'my-super-secret-key-2024'),
                       help='JWT secret key (default: from JWT_SECRET env or my-super-secret-key-2024)')
    parser.add_argument('--user', default='admin',
                       help='Username (default: admin)')
    parser.add_argument('--hours', type=int, default=24,
                       help='Token validity in hours (default: 24)')
    
    args = parser.parse_args()
    
    token = generate_jwt_token(args.secret, args.user, args.hours)
    
    print(f"\n{'='*60}")
    print(f"JWT Token Generated")
    print(f"{'='*60}")
    print(f"User:       {args.user}")
    print(f"Valid for:  {args.hours} hours")
    print(f"Secret:     {args.secret[:10]}...")
    print(f"\nToken:")
    print(f"{token}")
    print(f"\n{'='*60}")
    print(f"Usage Example:")
    print(f"{'='*60}")
    print(f'curl -X PATCH "http://localhost:8080/ngsi-ld/v1/entities/YOUR_ENTITY_ID/attrs" \\')
    print(f'  -H "Content-Type: application/json" \\')
    print(f'  -H "Authorization: Bearer {token}" \\')
    print(f"  -d '{{...}}'")
    print()

if __name__ == "__main__":
    main()
