"""
Document models for lifeOS backend
"""

from datetime import datetime
from typing import Dict, List, Optional
from pydantic import BaseModel, Field
from enum import Enum


class DocumentType(str, Enum):
    """Document type enumeration"""
    MARKDOWN = "markdown"  # AI-native markdown documents
    IMPORTED = "imported"  # Uploaded files
    LINKED = "linked"     # External links (Figma, Google Slides, etc.)


class DocumentStatus(str, Enum):
    """Document status enumeration"""
    DRAFT = "draft"
    PUBLISHED = "published"
    ARCHIVED = "archived"


class DocumentVersion(BaseModel):
    """Document version model for version control"""
    version_number: int
    content: str
    summary: Optional[str] = None  # AI-generated summary of changes
    
    # Version metadata
    created_by: str
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
    # Change tracking
    changes_summary: Optional[str] = None
    word_count: int = 0
    character_count: int = 0


class Document(BaseModel):
    """Document model for Firestore"""
    id: str
    title: str
    content: str = ""  # Current content (for markdown documents)
    
    # Document metadata
    document_type: DocumentType = DocumentType.MARKDOWN
    status: DocumentStatus = DocumentStatus.DRAFT
    
    # External document info (for imported/linked documents)
    file_url: Optional[str] = None
    file_name: Optional[str] = None
    file_size: Optional[int] = None
    mime_type: Optional[str] = None
    external_url: Optional[str] = None  # For linked documents
    
    # Content metadata
    word_count: int = 0
    character_count: int = 0
    estimated_read_time: int = 0  # In minutes
    
    # Version control
    current_version: int = 1
    versions: List[DocumentVersion] = Field(default_factory=list)
    
    # Collaboration
    collaborator_ids: List[str] = Field(default_factory=list)
    editor_ids: List[str] = Field(default_factory=list)  # Users with edit permissions
    viewer_ids: List[str] = Field(default_factory=list)   # Users with view permissions
    
    # Relationships
    owner_id: str = Field(..., description="Document owner")
    team_id: Optional[str] = None
    project_id: Optional[str] = None
    task_id: Optional[str] = None
    
    # Tags and categorization
    tags: List[str] = Field(default_factory=list)
    category: Optional[str] = None
    
    # AI interaction
    ai_summary: Optional[str] = None
    ai_last_updated: Optional[datetime] = None
    is_ai_editable: bool = True  # Whether AI can edit this document
    
    # Access control
    is_public: bool = False
    is_template: bool = False
    
    # Metadata
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    last_accessed: Optional[datetime] = None
    
    class Config:
        """Pydantic configuration"""
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }
    
    def calculate_read_time(self) -> int:
        """Calculate estimated read time based on word count"""
        # Average reading speed: 200-250 words per minute
        if self.word_count == 0:
            return 0
        return max(1, round(self.word_count / 225))
    
    def update_content_stats(self):
        """Update word count, character count, and read time"""
        self.word_count = len(self.content.split())
        self.character_count = len(self.content)
        self.estimated_read_time = self.calculate_read_time()
        self.updated_at = datetime.utcnow()
    
    def create_version(self, updated_by: str, summary: Optional[str] = None) -> DocumentVersion:
        """Create a new version of the document"""
        version = DocumentVersion(
            version_number=self.current_version + 1,
            content=self.content,
            summary=summary,
            created_by=updated_by,
            word_count=self.word_count,
            character_count=self.character_count
        )
        
        self.versions.append(version)
        self.current_version = version.version_number
        self.updated_at = datetime.utcnow()
        
        return version
    
    def add_collaborator(self, user_id: str, can_edit: bool = False):
        """Add a collaborator to the document"""
        if user_id not in self.collaborator_ids:
            self.collaborator_ids.append(user_id)
        
        if can_edit and user_id not in self.editor_ids:
            self.editor_ids.append(user_id)
        elif not can_edit and user_id not in self.viewer_ids:
            self.viewer_ids.append(user_id)
        
        self.updated_at = datetime.utcnow()
    
    def to_firestore(self) -> Dict:
        """Convert to Firestore document format"""
        data = self.dict()
        
        # Convert datetime objects to ISO strings
        datetime_fields = ['created_at', 'updated_at', 'last_accessed', 'ai_last_updated']
        for field in datetime_fields:
            if data.get(field):
                data[field] = data[field].isoformat()
        
        # Convert version datetime fields
        for version in data.get('versions', []):
            if version.get('created_at'):
                version['created_at'] = version['created_at'].isoformat()
        
        return data
    
    @classmethod
    def from_firestore(cls, doc_id: str, data: Dict) -> 'Document':
        """Create Document instance from Firestore document"""
        # Convert ISO strings back to datetime objects
        datetime_fields = ['created_at', 'updated_at', 'last_accessed', 'ai_last_updated']
        for field in datetime_fields:
            if data.get(field) and isinstance(data[field], str):
                data[field] = datetime.fromisoformat(data[field])
        
        # Convert version datetime fields
        for version in data.get('versions', []):
            if version.get('created_at') and isinstance(version['created_at'], str):
                version['created_at'] = datetime.fromisoformat(version['created_at'])
        
        data['id'] = doc_id
        return cls(**data)
