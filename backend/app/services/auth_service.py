"""
Authentication service for lifeOS backend
Mock implementation after Turso removal
"""

import os
import uuid
import base64
import secrets
from datetime import datetime, timedelta
from typing import Optional, Dict, List, Any

from app.core.config import settings
from app.models.user import User, UserProfile


class AuthService:
    """Mock authentication service (Turso service removed)"""
    
    def __init__(self):
        # In-memory storage for mock implementation
        self._users: Dict[str, Dict[str, Any]] = {}
        self._credentials: Dict[str, Dict[str, Any]] = {}
        self._challenges: Dict[str, Dict[str, Any]] = {}
    
    async def authenticate_user(self, email: str, password: str) -> Optional[User]:
        """Authenticate a user with email and password (mock implementation)"""
        print(f"Mock authentication attempt for: {email}")
        
        # Mock user data
        if email in self._users:
            user_data = self._users[email]
            return User(
                id=user_data["id"],
                email=user_data["email"],
                display_name=user_data["display_name"],
                created_at=user_data["created_at"],
                updated_at=user_data["updated_at"]
            )
        
        return None
    
    async def create_user(self, email: str, display_name: str, password: str) -> Optional[User]:
        """Create a new user (mock implementation)"""
        print(f"Mock user creation for: {email}")
        
        # Check if user already exists
        if email in self._users:
            print(f"User {email} already exists")
            return None
        
        # Create mock user
        user_id = str(uuid.uuid4())
        now = datetime.utcnow().isoformat()
        
        user_data = {
            "id": user_id,
            "email": email,
            "display_name": display_name,
            "created_at": now,
            "updated_at": now
        }
        
        self._users[email] = user_data
        
        return User(
            id=user_id,
            email=email,
            display_name=display_name,
            created_at=now,
            updated_at=now
        )
    
    async def get_user_by_id(self, user_id: str) -> Optional[User]:
        """Get user by ID (mock implementation)"""
        for user_data in self._users.values():
            if user_data["id"] == user_id:
                return User(
                    id=user_data["id"],
                    email=user_data["email"],
                    display_name=user_data["display_name"],
                    created_at=user_data["created_at"],
                    updated_at=user_data["updated_at"]
                )
        return None
    
    async def register_webauthn_begin(self, user_id: str) -> Dict[str, Any]:
        """Begin WebAuthn registration (mock implementation)"""
        print(f"Mock WebAuthn registration begin for user: {user_id}")
        
        # Generate mock challenge
        challenge = base64.urlsafe_b64encode(secrets.token_bytes(32)).decode('utf-8')
        challenge_id = f"reg_{user_id}_{int(datetime.utcnow().timestamp())}"
        
        # Store challenge
        self._challenges[challenge_id] = {
            "id": challenge_id,
            "challenge": challenge,
            "user_id": user_id,
            "created_at": datetime.utcnow().isoformat()
        }
        
        return {
            "challenge": challenge,
            "challenge_id": challenge_id,
            "rp": {"name": "lifeOS", "id": "localhost"},
            "user": {"id": user_id, "name": "user", "displayName": "User"},
            "pubKeyCredParams": [{"type": "public-key", "alg": -7}],
            "timeout": 60000,
            "attestation": "none"
        }
    
    async def register_webauthn_complete(self, user_id: str, credential_data: Dict[str, Any], challenge_id: str) -> bool:
        """Complete WebAuthn registration (mock implementation)"""
        print(f"Mock WebAuthn registration complete for user: {user_id}")
        
        # Mock verification - always succeed
        credential_id = credential_data.get('id', str(uuid.uuid4()))
        
        # Store mock credential
        self._credentials[credential_id] = {
            "credential_id": credential_id,
            "user_id": user_id,
            "public_key": "mock_public_key",
            "sign_count": 0,
            "created_at": datetime.utcnow().isoformat()
        }
        
        # Clean up challenge
        if challenge_id in self._challenges:
            del self._challenges[challenge_id]
        
        return True
    
    async def authenticate_webauthn_begin(self, email: str) -> Dict[str, Any]:
        """Begin WebAuthn authentication (mock implementation)"""
        print(f"Mock WebAuthn authentication begin for: {email}")
        
        # Find user
        if email not in self._users:
            raise Exception("User not found")
        
        user_data = self._users[email]
        user_id = user_data["id"]
        
        # Generate mock challenge
        challenge = base64.urlsafe_b64encode(secrets.token_bytes(32)).decode('utf-8')
        challenge_id = f"auth_{user_id}_{int(datetime.utcnow().timestamp())}"
        
        # Store challenge
        self._challenges[challenge_id] = {
            "id": challenge_id,
            "challenge": challenge,
            "user_id": user_id,
            "email": email,
            "created_at": datetime.utcnow().isoformat()
        }
        
        # Get mock credentials
        user_credentials = [
            {"id": cred["credential_id"], "type": "public-key"}
            for cred in self._credentials.values()
            if cred["user_id"] == user_id
        ]
        
        return {
            "challenge": challenge,
            "challenge_id": challenge_id,
            "allowCredentials": user_credentials,
            "timeout": 60000,
            "userVerification": "preferred"
        }
    
    async def authenticate_webauthn_complete(self, email: str, credential_data: Dict[str, Any], challenge_id: str) -> Optional[User]:
        """Complete WebAuthn authentication (mock implementation)"""
        print(f"Mock WebAuthn authentication complete for: {email}")
        
        # Find user
        if email not in self._users:
            return None
        
        user_data = self._users[email]
        
        # Mock verification - always succeed if credential exists
        credential_id = credential_data.get('id')
        if credential_id in self._credentials:
            # Clean up challenge
            if challenge_id in self._challenges:
                del self._challenges[challenge_id]
            
            return User(
                id=user_data["id"],
                email=user_data["email"],
                display_name=user_data["display_name"],
                created_at=user_data["created_at"],
                updated_at=user_data["updated_at"]
            )
        
        return None


# Global auth service instance
auth_service = AuthService()
