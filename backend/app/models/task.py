"""
Task models for lifeOS backend
"""

from datetime import datetime
from typing import Dict, List, Optional
from pydantic import BaseModel, Field
from enum import Enum


class TaskStatus(str, Enum):
    """Task status enumeration"""
    BACKLOG = "backlog"
    TODO = "todo"
    IN_PROGRESS = "in_progress"
    DONE = "done"
    CANCELLED = "cancelled"


class TaskPriority(str, Enum):
    """Task priority enumeration"""
    URGENT = "urgent"
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"
    NONE = "none"


class TeamRole(str, Enum):
    """Team role enumeration for task assignments"""
    LEADER = "leader"
    DESIGNER = "designer"
    BUILDER = "builder"


class TaskAssignment(BaseModel):
    """Task assignment model"""
    user_id: str
    role: TeamRole
    assigned_at: datetime = Field(default_factory=datetime.utcnow)
    assigned_by: str  # User ID who made the assignment


class Task(BaseModel):
    """Task (Quest) model for Firestore"""
    id: str
    title: str
    description: Optional[str] = None
    
    # Quest document (markdown content)
    quest_document: str = ""
    
    # Status and priority
    status: TaskStatus = TaskStatus.BACKLOG
    priority: TaskPriority = TaskPriority.MEDIUM
    
    # Time estimation and tracking
    estimated_hours: Optional[float] = None
    actual_hours: Optional[float] = None
    time_spent: float = 0.0  # Time currency spent
    
    # Assignments
    quest_team: List[TaskAssignment] = Field(default_factory=list)
    
    # Relationships
    project_id: str = Field(..., description="Parent project ID")
    goal_id: Optional[str] = None  # Linked goal
    parent_task_id: Optional[str] = None  # For subtasks
    subtask_ids: List[str] = Field(default_factory=list)
    
    # Dependencies
    depends_on: List[str] = Field(default_factory=list, description="Task IDs this depends on")
    blocks: List[str] = Field(default_factory=list, description="Task IDs this blocks")
    
    # Attachments and references
    attached_document_ids: List[str] = Field(default_factory=list)
    chat_room_id: Optional[str] = None  # Dedicated chat for this task
    
    # Gamification
    knowledge_reward: int = Field(default=10, description="Knowledge points for completion")
    gratification_rating: Optional[int] = Field(None, ge=1, le=5, description="User's enjoyment rating")
    
    # Timeline
    due_date: Optional[datetime] = None
    start_date: Optional[datetime] = None
    completed_date: Optional[datetime] = None
    
    # Metadata
    created_by: str = Field(..., description="User ID of creator")
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    last_activity: Optional[datetime] = None
    
    # Flags
    is_drifting: bool = False  # Auto-calculated based on inactivity
    is_blocked: bool = False
    
    class Config:
        """Pydantic configuration"""
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }
    
    def is_overdue(self) -> bool:
        """Check if task is overdue"""
        if not self.due_date:
            return False
        return datetime.utcnow() > self.due_date and self.status != TaskStatus.DONE
    
    def calculate_drift_status(self, drift_threshold_days: int = 7) -> bool:
        """Calculate if task is drifting based on last activity"""
        if self.status == TaskStatus.DONE:
            return False
        
        if not self.last_activity:
            # Use created_at if no activity recorded
            last_activity = self.created_at
        else:
            last_activity = self.last_activity
        
        days_inactive = (datetime.utcnow() - last_activity).days
        return days_inactive >= drift_threshold_days
    
    def get_assigned_users(self, role: Optional[TeamRole] = None) -> List[str]:
        """Get list of assigned user IDs, optionally filtered by role"""
        if role:
            return [assignment.user_id for assignment in self.quest_team if assignment.role == role]
        return [assignment.user_id for assignment in self.quest_team]
    
    def add_assignment(self, user_id: str, role: TeamRole, assigned_by: str):
        """Add a new assignment to the task"""
        # Remove existing assignment for this user if any
        self.quest_team = [a for a in self.quest_team if a.user_id != user_id]
        
        # Add new assignment
        assignment = TaskAssignment(
            user_id=user_id,
            role=role,
            assigned_by=assigned_by
        )
        self.quest_team.append(assignment)
        self.updated_at = datetime.utcnow()
    
    def complete_task(self, completed_by: str, gratification_rating: Optional[int] = None):
        """Mark task as completed"""
        self.status = TaskStatus.DONE
        self.completed_date = datetime.utcnow()
        self.updated_at = datetime.utcnow()
        
        if gratification_rating:
            self.gratification_rating = gratification_rating
    
    def to_firestore(self) -> Dict:
        """Convert to Firestore document format"""
        data = self.dict()
        
        # Convert datetime objects to ISO strings
        datetime_fields = [
            'due_date', 'start_date', 'completed_date', 
            'created_at', 'updated_at', 'last_activity'
        ]
        for field in datetime_fields:
            if data.get(field):
                data[field] = data[field].isoformat()
        
        # Convert assignment datetime fields
        for assignment in data.get('quest_team', []):
            if assignment.get('assigned_at'):
                assignment['assigned_at'] = assignment['assigned_at'].isoformat()
        
        return data
    
    @classmethod
    def from_firestore(cls, doc_id: str, data: Dict) -> 'Task':
        """Create Task instance from Firestore document"""
        # Convert ISO strings back to datetime objects
        datetime_fields = [
            'due_date', 'start_date', 'completed_date',
            'created_at', 'updated_at', 'last_activity'
        ]
        for field in datetime_fields:
            if data.get(field) and isinstance(data[field], str):
                data[field] = datetime.fromisoformat(data[field])
        
        # Convert assignment datetime fields
        for assignment in data.get('quest_team', []):
            if assignment.get('assigned_at') and isinstance(assignment['assigned_at'], str):
                assignment['assigned_at'] = datetime.fromisoformat(assignment['assigned_at'])
        
        data['id'] = doc_id
        return cls(**data)
