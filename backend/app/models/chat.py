"""
Chat models for lifeOS backend
"""

from datetime import datetime
from typing import Dict, List, Optional
from pydantic import BaseModel, Field
from enum import Enum


class ChatRoomType(str, Enum):
    """Chat room type enumeration"""
    DIRECT = "direct"  # 1-on-1 chat
    GROUP = "group"    # Group chat
    TEAM = "team"      # Team-wide chat
    PROJECT = "project"  # Project-specific chat
    TASK = "task"      # Task-specific chat


class MessageType(str, Enum):
    """Message type enumeration"""
    TEXT = "text"
    FILE = "file"
    IMAGE = "image"
    SYSTEM = "system"  # System-generated messages
    AI_RESPONSE = "ai_response"  # AI assistant responses


class ChatMessage(BaseModel):
    """Chat message model"""
    id: str
    content: str
    message_type: MessageType = MessageType.TEXT
    
    # Sender information
    sender_id: str
    sender_name: str  # Cached for performance
    
    # File attachments (for file/image messages)
    file_url: Optional[str] = None
    file_name: Optional[str] = None
    file_size: Optional[int] = None
    
    # Message metadata
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: Optional[datetime] = None
    is_edited: bool = False
    
    # Threading
    reply_to_id: Optional[str] = None  # For threaded conversations
    thread_count: int = 0  # Number of replies
    
    # Reactions and interactions
    reactions: Dict[str, List[str]] = Field(default_factory=dict)  # emoji -> [user_ids]
    mentions: List[str] = Field(default_factory=list)  # Mentioned user IDs
    
    # AI context (for AI responses)
    ai_context: Optional[Dict] = None


class ChatRoom(BaseModel):
    """Chat room model for Firestore"""
    id: str
    name: Optional[str] = None  # Optional for direct chats
    description: Optional[str] = None
    
    # Room configuration
    room_type: ChatRoomType
    is_private: bool = True
    
    # Participants
    participant_ids: List[str] = Field(default_factory=list)
    admin_ids: List[str] = Field(default_factory=list)
    
    # Related entities
    team_id: Optional[str] = None
    project_id: Optional[str] = None
    task_id: Optional[str] = None
    
    # Message management
    last_message_id: Optional[str] = None
    last_message_at: Optional[datetime] = None
    message_count: int = 0
    
    # Settings
    allow_ai_assistant: bool = True
    notification_settings: Dict[str, bool] = Field(default_factory=lambda: {
        "all_messages": True,
        "mentions_only": False,
        "muted": False
    })
    
    # Metadata
    created_by: str
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Config:
        """Pydantic configuration"""
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }
    
    def add_participant(self, user_id: str, is_admin: bool = False):
        """Add a participant to the chat room"""
        if user_id not in self.participant_ids:
            self.participant_ids.append(user_id)
        
        if is_admin and user_id not in self.admin_ids:
            self.admin_ids.append(user_id)
        
        self.updated_at = datetime.utcnow()
    
    def remove_participant(self, user_id: str):
        """Remove a participant from the chat room"""
        if user_id in self.participant_ids:
            self.participant_ids.remove(user_id)
        
        if user_id in self.admin_ids:
            self.admin_ids.remove(user_id)
        
        self.updated_at = datetime.utcnow()
    
    def to_firestore(self) -> Dict:
        """Convert to Firestore document format"""
        data = self.dict()
        # Convert datetime objects to ISO strings
        datetime_fields = ['last_message_at', 'created_at', 'updated_at']
        for field in datetime_fields:
            if data.get(field):
                data[field] = data[field].isoformat()
        
        return data
    
    @classmethod
    def from_firestore(cls, doc_id: str, data: Dict) -> 'ChatRoom':
        """Create ChatRoom instance from Firestore document"""
        # Convert ISO strings back to datetime objects
        datetime_fields = ['last_message_at', 'created_at', 'updated_at']
        for field in datetime_fields:
            if data.get(field) and isinstance(data[field], str):
                data[field] = datetime.fromisoformat(data[field])
        
        data['id'] = doc_id
        return cls(**data)
