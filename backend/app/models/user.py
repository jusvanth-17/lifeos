"""
User models for lifeOS backend
"""

from datetime import datetime
from typing import Dict, List, Optional
from pydantic import BaseModel, Field
from enum import Enum


class FocusMode(str, Enum):
    """Focus mode enumeration"""
    ME = "me"
    WORK = "work"
    COMMUNITY = "community"


class SkillLevel(BaseModel):
    """Skill level representation"""
    visionary: int = Field(default=1, ge=1, le=100)
    leader: int = Field(default=1, ge=1, le=100)
    builder: int = Field(default=1, ge=1, le=100)


class Currencies(BaseModel):
    """User currencies for gamification"""
    time_daily: int = Field(default=8, description="Daily time budget in hours")
    time_remaining: int = Field(default=8, description="Remaining time for today")
    knowledge: int = Field(default=0, description="Knowledge points earned")
    gratification: int = Field(default=0, description="Gratification points")
    credits: int = Field(default=0, description="Community credits")


class UserProfile(BaseModel):
    """User profile information"""
    display_name: str
    avatar_url: Optional[str] = None
    bio: Optional[str] = None
    location: Optional[str] = None
    timezone: str = "UTC"
    
    # Gamification
    skill_levels: SkillLevel = Field(default_factory=SkillLevel)
    currencies: Currencies = Field(default_factory=Currencies)
    achievements: List[str] = Field(default_factory=list)
    
    # Health metrics
    personal_health: int = Field(default=50, ge=0, le=100)
    team_health: int = Field(default=50, ge=0, le=100)
    
    # Preferences
    focus_mode: FocusMode = FocusMode.WORK
    notification_settings: Dict[str, bool] = Field(default_factory=lambda: {
        "email_notifications": True,
        "push_notifications": True,
        "task_reminders": True,
        "team_updates": True
    })


class User(BaseModel):
    """User model for Firestore"""
    id: str = Field(..., description="User ID (from Firebase Auth)")
    email: str
    profile: UserProfile
    
    # Metadata
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    last_active: Optional[datetime] = None
    
    # Relationships
    team_memberships: List[str] = Field(default_factory=list, description="Team IDs")
    project_memberships: List[str] = Field(default_factory=list, description="Project IDs")
    
    # Settings
    is_active: bool = True
    is_verified: bool = False
    
    class Config:
        """Pydantic configuration"""
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }
        
    def to_firestore(self) -> Dict:
        """Convert to Firestore document format"""
        data = self.dict()
        # Convert datetime objects to Firestore timestamps
        for field in ['created_at', 'updated_at', 'last_active']:
            if data.get(field):
                data[field] = data[field].isoformat()
        return data
    
    @classmethod
    def from_firestore(cls, doc_id: str, data: Dict) -> 'User':
        """Create User instance from Firestore document"""
        # Convert ISO strings back to datetime objects
        for field in ['created_at', 'updated_at', 'last_active']:
            if data.get(field) and isinstance(data[field], str):
                data[field] = datetime.fromisoformat(data[field])
        
        data['id'] = doc_id
        return cls(**data)
