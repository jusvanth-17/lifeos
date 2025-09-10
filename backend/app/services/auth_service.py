"""
Authentication service for lifeOS backend
Mock implementation after Turso removal
"""

import os
import uuid
import base64
import secrets
import jwt
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
            profile = UserProfile(**user_data["profile"])
            return User(
                id=user_data["id"],
                email=user_data["email"],
                profile=profile,
                created_at=datetime.fromisoformat(user_data["created_at"]),
                updated_at=datetime.fromisoformat(user_data["updated_at"])
            )
        
        return None
    
    async def create_user(self, email: str, display_name: str, password: str = None) -> Optional[User]:
        """Create a new user (mock implementation)"""
        print(f"Mock user creation for: {email}")
        
        # Check if user already exists
        if email in self._users:
            print(f"User {email} already exists")
            return None
        
        # Create mock user
        user_id = str(uuid.uuid4())
        now = datetime.utcnow()
        
        # Create user profile
        profile = UserProfile(display_name=display_name)
        
        user_data = {
            "id": user_id,
            "email": email,
            "profile": profile.dict(),
            "created_at": now.isoformat(),
            "updated_at": now.isoformat()
        }
        
        self._users[email] = user_data
        
        return User(
            id=user_id,
            email=email,
            profile=profile,
            created_at=now,
            updated_at=now
        )
    
    async def get_user_by_id(self, user_id: str) -> Optional[User]:
        """Get user by ID (mock implementation)"""
        for user_data in self._users.values():
            if user_data["id"] == user_id:
                profile = UserProfile(**user_data["profile"])
                return User(
                    id=user_data["id"],
                    email=user_data["email"],
                    profile=profile,
                    created_at=datetime.fromisoformat(user_data["created_at"]),
                    updated_at=datetime.fromisoformat(user_data["updated_at"])
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
            
            profile = UserProfile(**user_data["profile"])
            return User(
                id=user_data["id"],
                email=user_data["email"],
                profile=profile,
                created_at=datetime.fromisoformat(user_data["created_at"]),
                updated_at=datetime.fromisoformat(user_data["updated_at"])
            )
        
        return None


    # JWT Token Management Methods
    def create_access_token(self, user_id: str, expires_delta: Optional[timedelta] = None) -> str:
        """Create JWT access token"""
        if expires_delta:
            expire = datetime.utcnow() + expires_delta
        else:
            expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        
        to_encode = {
            "sub": user_id,
            "exp": expire,
            "type": "access"
        }
        
        encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
        return encoded_jwt
    
    def decode_access_token(self, token: str) -> Optional[Dict[str, Any]]:
        """Decode JWT access token"""
        try:
            payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
            return payload
        except jwt.PyJWTError:
            return None
    
    async def get_current_user(self, token: str) -> Optional[User]:
        """Get current user from JWT token"""
        payload = self.decode_access_token(token)
        if payload is None:
            return None
        
        user_id = payload.get("sub")
        if user_id is None:
            return None
        
        return await self.get_user_by_id(user_id)
    
    # API-Expected Method Wrappers
    async def start_webauthn_registration(self, user_id: str, email: str, display_name: str) -> Dict[str, Any]:
        """Start WebAuthn registration process (API wrapper)"""
        return await self.register_webauthn_begin(user_id)
    
    async def complete_webauthn_registration(self, user_id: str, credential_data: Dict[str, Any]) -> bool:
        """Complete WebAuthn registration process (API wrapper)"""
        # Extract challenge_id from credential if available, otherwise use a mock one
        challenge_id = f"reg_{user_id}_{int(datetime.utcnow().timestamp())}"
        return await self.register_webauthn_complete(user_id, credential_data, challenge_id)
    
    async def start_webauthn_authentication(self, email: str) -> Dict[str, Any]:
        """Start WebAuthn authentication process (API wrapper)"""
        return await self.authenticate_webauthn_begin(email)
    
    async def complete_webauthn_authentication(self, email: str, credential_data: Dict[str, Any]) -> Optional[str]:
        """Complete WebAuthn authentication process and return JWT token"""
        challenge_id = f"auth_{email}_{int(datetime.utcnow().timestamp())}"
        user = await self.authenticate_webauthn_complete(email, credential_data, challenge_id)
        
        if user:
            # Generate JWT token for authenticated user
            return self.create_access_token(user.id)
        
        return None


# Global auth service instance
auth_service = AuthService()
