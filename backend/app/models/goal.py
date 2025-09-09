"""
Goal models for lifeOS backend
"""

from datetime import datetime
from typing import Dict, List, Optional
from pydantic import BaseModel, Field
from enum import Enum
from .user import FocusMode


class GoalStatus(str, Enum):
    """Goal status enumeration"""
    DRAFT = "draft"
    ACTIVE = "active"
    COMPLETED = "completed"
    PAUSED = "paused"
    CANCELLED = "cancelled"


class KeyResultType(str, Enum):
    """Key result type enumeration"""
    METRIC = "metric"
    COMPLETION = "completion"


class KeyResult(BaseModel):
    """Key result model"""
    id: str
    title: str
    description: Optional[str] = None
    type: KeyResultType
    
    # For metric-based KRs
    target_value: Optional[float] = None
    current_value: float = 0.0
    unit: Optional[str] = None
    
    # For completion-based KRs
    is_completed: bool = False
    
    # Progress calculation
    progress_percentage: float = Field(default=0.0, ge=0.0, le=100.0)
    
    # Metadata
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    def calculate_progress(self) -> float:
        """Calculate progress percentage"""
        if self.type == KeyResultType.COMPLETION:
            return 100.0 if self.is_completed else 0.0
        elif self.type == KeyResultType.METRIC and self.target_value:
            if self.target_value > 0:
                progress = (self.current_value / self.target_value) * 100
                return min(100.0, max(0.0, progress))
        return 0.0


class Goal(BaseModel):
    """Goal model for Firestore"""
    id: str
    title: str
    description: Optional[str] = None
    
    # Categorization
    focus_mode: FocusMode
    status: GoalStatus = GoalStatus.DRAFT
    
    # Timeline
    target_date: Optional[datetime] = None
    start_date: Optional[datetime] = None
    completed_date: Optional[datetime] = None
    
    # Key Results
    key_results: List[KeyResult] = Field(default_factory=list)
    
    # Progress tracking
    progress_percentage: float = Field(default=0.0, ge=0.0, le=100.0)
    
    # Relationships
    owner_id: str = Field(..., description="User ID of goal owner")
    linked_project_ids: List[str] = Field(default_factory=list)
    
    # Metadata
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Config:
        """Pydantic configuration"""
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }
    
    def calculate_progress(self) -> float:
        """Calculate overall goal progress based on key results"""
        if not self.key_results:
            return 0.0
        
        total_progress = sum(kr.calculate_progress() for kr in self.key_results)
        return total_progress / len(self.key_results)
    
    def update_progress(self):
        """Update progress percentage and status"""
        self.progress_percentage = self.calculate_progress()
        self.updated_at = datetime.utcnow()
        
        # Auto-complete goal if all key results are at 100%
        if self.progress_percentage >= 100.0 and self.status == GoalStatus.ACTIVE:
            self.status = GoalStatus.COMPLETED
            self.completed_date = datetime.utcnow()
    
    def to_firestore(self) -> Dict:
        """Convert to Firestore document format"""
        data = self.dict()
        # Convert datetime objects to ISO strings
        datetime_fields = ['target_date', 'start_date', 'completed_date', 'created_at', 'updated_at']
        for field in datetime_fields:
            if data.get(field):
                data[field] = data[field].isoformat()
        
        # Convert key results datetime fields
        for kr in data.get('key_results', []):
            for field in ['created_at', 'updated_at']:
                if kr.get(field):
                    kr[field] = kr[field].isoformat()
        
        return data
    
    @classmethod
    def from_firestore(cls, doc_id: str, data: Dict) -> 'Goal':
        """Create Goal instance from Firestore document"""
        # Convert ISO strings back to datetime objects
        datetime_fields = ['target_date', 'start_date', 'completed_date', 'created_at', 'updated_at']
        for field in datetime_fields:
            if data.get(field) and isinstance(data[field], str):
                data[field] = datetime.fromisoformat(data[field])
        
        # Convert key results datetime fields
        for kr in data.get('key_results', []):
            for field in ['created_at', 'updated_at']:
                if kr.get(field) and isinstance(kr[field], str):
                    kr[field] = datetime.fromisoformat(kr[field])
        
        data['id'] = doc_id
        return cls(**data)
