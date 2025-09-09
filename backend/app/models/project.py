"""
Project models for lifeOS backend
"""

from datetime import datetime
from typing import Dict, List, Optional
from pydantic import BaseModel, Field
from enum import Enum
from .team import TeamMemberRole


class ProjectStatus(str, Enum):
    """Project status enumeration"""
    PLANNING = "planning"
    ACTIVE = "active"
    ON_HOLD = "on_hold"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


class ProjectMember(BaseModel):
    """Project member model"""
    user_id: str
    role: TeamMemberRole
    joined_at: datetime = Field(default_factory=datetime.utcnow)
    added_by: str


class Project(BaseModel):
    """Project model for Firestore"""
    id: str
    name: str
    description: Optional[str] = None
    
    # Status and progress
    status: ProjectStatus = ProjectStatus.PLANNING
    progress_percentage: float = Field(default=0.0, ge=0.0, le=100.0)
    
    # Relationships
    team_id: str = Field(..., description="Parent team ID")
    goal_id: Optional[str] = None  # Linked goal
    members: List[ProjectMember] = Field(default_factory=list)
    
    # Timeline
    start_date: Optional[datetime] = None
    due_date: Optional[datetime] = None
    completed_date: Optional[datetime] = None
    
    # Task management
    task_ids: List[str] = Field(default_factory=list)
    
    # Documents and chat
    document_ids: List[str] = Field(default_factory=list)
    chat_room_id: Optional[str] = None
    
    # Metadata
    created_by: str
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Config:
        """Pydantic configuration"""
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }
    
    def calculate_progress(self, completed_tasks: int, total_tasks: int) -> float:
        """Calculate project progress based on completed tasks"""
        if total_tasks == 0:
            return 0.0
        return (completed_tasks / total_tasks) * 100.0
    
    def to_firestore(self) -> Dict:
        """Convert to Firestore document format"""
        data = self.dict()
        # Convert datetime objects to ISO strings
        datetime_fields = ['start_date', 'due_date', 'completed_date', 'created_at', 'updated_at']
        for field in datetime_fields:
            if data.get(field):
                data[field] = data[field].isoformat()
        
        # Convert member datetime fields
        for member in data.get('members', []):
            if member.get('joined_at'):
                member['joined_at'] = member['joined_at'].isoformat()
        
        return data
    
    @classmethod
    def from_firestore(cls, doc_id: str, data: Dict) -> 'Project':
        """Create Project instance from Firestore document"""
        # Convert ISO strings back to datetime objects
        datetime_fields = ['start_date', 'due_date', 'completed_date', 'created_at', 'updated_at']
        for field in datetime_fields:
            if data.get(field) and isinstance(data[field], str):
                data[field] = datetime.fromisoformat(data[field])
        
        # Convert member datetime fields
        for member in data.get('members', []):
            if member.get('joined_at') and isinstance(member['joined_at'], str):
                member['joined_at'] = datetime.fromisoformat(member['joined_at'])
        
        data['id'] = doc_id
        return cls(**data)
