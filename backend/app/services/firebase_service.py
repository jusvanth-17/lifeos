"""
Firebase service for Firestore operations
"""

import json
import os
from typing import Dict, List, Optional, Any, Type, TypeVar
from datetime import datetime

# Note: These imports will work once Firebase dependencies are installed
try:
    import firebase_admin
    from firebase_admin import credentials, firestore
    from google.cloud.firestore_v1 import FieldFilter
    FIREBASE_AVAILABLE = True
except ImportError:
    FIREBASE_AVAILABLE = False

from app.core.config import settings

T = TypeVar('T')


class FirebaseService:
    """Firebase service for Firestore operations"""
    
    def __init__(self):
        self._db = None
        self._initialized = False
    
    def initialize(self) -> bool:
        """Initialize Firebase connection"""
        if not FIREBASE_AVAILABLE:
            print("Warning: Firebase dependencies not available. Using mock mode.")
            return False
        
        if self._initialized:
            return True
        
        try:
            # Check if Firebase is already initialized
            if not firebase_admin._apps:
                # Create credentials from environment variables
                if all([
                    settings.FIREBASE_PROJECT_ID,
                    settings.FIREBASE_PRIVATE_KEY_ID,
                    settings.FIREBASE_PRIVATE_KEY,
                    settings.FIREBASE_CLIENT_EMAIL,
                    settings.FIREBASE_CLIENT_ID
                ]):
                    # Create credentials dict
                    cred_dict = {
                        "type": "service_account",
                        "project_id": settings.FIREBASE_PROJECT_ID,
                        "private_key_id": settings.FIREBASE_PRIVATE_KEY_ID,
                        "private_key": settings.FIREBASE_PRIVATE_KEY.replace('\\n', '\n'),
                        "client_email": settings.FIREBASE_CLIENT_EMAIL,
                        "client_id": settings.FIREBASE_CLIENT_ID,
                        "auth_uri": settings.FIREBASE_AUTH_URI,
                        "token_uri": settings.FIREBASE_TOKEN_URI,
                    }
                    
                    cred = credentials.Certificate(cred_dict)
                    firebase_admin.initialize_app(cred)
                else:
                    print("Warning: Firebase credentials not configured. Using mock mode.")
                    return False
            
            self._db = firestore.client()
            self._initialized = True
            print("✅ Firebase initialized successfully")
            return True
            
        except Exception as e:
            print(f"❌ Failed to initialize Firebase: {e}")
            return False
    
    @property
    def db(self):
        """Get Firestore database client"""
        if not self._initialized:
            self.initialize()
        return self._db
    
    # Generic CRUD operations
    async def create_document(self, collection: str, document_id: str, data: Dict) -> bool:
        """Create a new document"""
        if not self.db:
            print(f"Mock: Creating document {document_id} in {collection}")
            return True
        
        try:
            doc_ref = self.db.collection(collection).document(document_id)
            doc_ref.set(data)
            return True
        except Exception as e:
            print(f"Error creating document: {e}")
            return False
    
    async def get_document(self, collection: str, document_id: str) -> Optional[Dict]:
        """Get a document by ID"""
        if not self.db:
            print(f"Mock: Getting document {document_id} from {collection}")
            return None
        
        try:
            doc_ref = self.db.collection(collection).document(document_id)
            doc = doc_ref.get()
            
            if doc.exists:
                return doc.to_dict()
            return None
        except Exception as e:
            print(f"Error getting document: {e}")
            return None
    
    async def update_document(self, collection: str, document_id: str, data: Dict) -> bool:
        """Update a document"""
        if not self.db:
            print(f"Mock: Updating document {document_id} in {collection}")
            return True
        
        try:
            doc_ref = self.db.collection(collection).document(document_id)
            doc_ref.update(data)
            return True
        except Exception as e:
            print(f"Error updating document: {e}")
            return False
    
    async def delete_document(self, collection: str, document_id: str) -> bool:
        """Delete a document"""
        if not self.db:
            print(f"Mock: Deleting document {document_id} from {collection}")
            return True
        
        try:
            doc_ref = self.db.collection(collection).document(document_id)
            doc_ref.delete()
            return True
        except Exception as e:
            print(f"Error deleting document: {e}")
            return False
    
    async def query_documents(
        self, 
        collection: str, 
        filters: Optional[List[tuple]] = None,
        order_by: Optional[str] = None,
        limit: Optional[int] = None
    ) -> List[Dict]:
        """Query documents with filters"""
        if not self.db:
            print(f"Mock: Querying documents from {collection}")
            return []
        
        try:
            query = self.db.collection(collection)
            
            # Apply filters
            if filters:
                for field, operator, value in filters:
                    query = query.where(filter=FieldFilter(field, operator, value))
            
            # Apply ordering
            if order_by:
                query = query.order_by(order_by)
            
            # Apply limit
            if limit:
                query = query.limit(limit)
            
            docs = query.stream()
            results = []
            
            for doc in docs:
                doc_data = doc.to_dict()
                doc_data['id'] = doc.id
                results.append(doc_data)
            
            return results
        except Exception as e:
            print(f"Error querying documents: {e}")
            return []
    
    # Collection-specific methods
    async def get_user_by_email(self, email: str) -> Optional[Dict]:
        """Get user by email"""
        users = await self.query_documents(
            "users",
            filters=[("email", "==", email)],
            limit=1
        )
        return users[0] if users else None
    
    async def get_user_teams(self, user_id: str) -> List[Dict]:
        """Get teams for a user"""
        return await self.query_documents(
            "teams",
            filters=[("members", "array_contains", {"user_id": user_id})]
        )
    
    async def get_team_projects(self, team_id: str) -> List[Dict]:
        """Get projects for a team"""
        return await self.query_documents(
            "projects",
            filters=[("team_id", "==", team_id)],
            order_by="created_at"
        )
    
    async def get_project_tasks(self, project_id: str) -> List[Dict]:
        """Get tasks for a project"""
        return await self.query_documents(
            "tasks",
            filters=[("project_id", "==", project_id)],
            order_by="created_at"
        )
    
    async def get_user_goals(self, user_id: str, focus_mode: Optional[str] = None) -> List[Dict]:
        """Get goals for a user, optionally filtered by focus mode"""
        filters = [("owner_id", "==", user_id)]
        if focus_mode:
            filters.append(("focus_mode", "==", focus_mode))
        
        return await self.query_documents(
            "goals",
            filters=filters,
            order_by="created_at"
        )
    
    async def get_chat_messages(self, chat_room_id: str, limit: int = 50) -> List[Dict]:
        """Get recent messages for a chat room"""
        return await self.query_documents(
            f"chat_rooms/{chat_room_id}/messages",
            order_by="created_at",
            limit=limit
        )
    
    # Real-time listeners (placeholder for WebSocket implementation)
    def listen_to_collection(self, collection: str, callback):
        """Set up real-time listener for a collection"""
        if not self.db:
            print(f"Mock: Setting up listener for {collection}")
            return
        
        # This would be implemented for real-time updates
        # For now, it's a placeholder
        pass


# Global Firebase service instance
firebase_service = FirebaseService()
