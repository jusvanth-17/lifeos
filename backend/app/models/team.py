"""
Team models for lifeOS backend
"""

from datetime import datetime
from typing import Dict, List, Optional
from pydantic import BaseModel, Field
from enum import Enum


class TeamMemberRole(str, Enum):
    """Team member role enumeration"""
    OWNER = "owner"
    ADMIN = "admin"
    MEMBER = "member"
    GUEST = "guest"


class TeamMember(BaseModel):
    """Team member model"""
    user_id: str
    role: TeamMemberRole
    joined_at: datetime = Field(default_factory=datetime.utcnow)
    invited_by: Optional[str] = None


class Team(BaseModel):
    """Team model for Firestore"""
    id: str
    name: str
    description: Optional[str] = None
    avatar_url: Optional[str] = None
    
    # Members
    members: List[TeamMember] = Field(default_factory=list)
    
    # Settings
    is_public: bool = False
    allow_guest_access: bool = False
    
    # Metadata
    created_by: str
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Config:
        """Pydantic configuration"""
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }
    
    def to_firestore(self) -> Dict:
        """Convert to Firestore document format"""
        data = self.dict()
        # Convert datetime objects to ISO strings
        for field in ['created_at', 'updated_at']:
            if data.get(field):
                data[field] = data[field].isoformat()
        
        # Convert member datetime fields
        for member in data.get('members', []):
            if member.get('joined_at'):
                member['joined_at'] = member['joined_at'].isoformat()
        
        return data
    
    @classmethod
    def from_firestore(cls, doc_id: str, data: Dict) -> 'Team':
        """Create Team instance from Firestore document"""
        # Convert ISO strings back to datetime objects
        for field in ['created_at', 'updated_at']:
            if data.get(field) and isinstance(data[field], str):
                data[field] = datetime.fromisoformat(data[field])
        
        # Convert member datetime fields
        for member in data.get('members', []):
            if member.get('joined_at') and isinstance(member['joined_at'], str):
                member['joined_at'] = datetime.fromisoformat(member['joined_at'])
        
        data['id'] = doc_id
        return cls(**data)
