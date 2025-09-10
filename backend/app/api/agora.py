"""
Agora API endpoints for video/audio calling functionality
"""

from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional
import time
from agora_token_builder import RtcTokenBuilder
from agora_token_builder.RtcTokenBuilder import Role_Attendee, Role_Publisher
import os
from ..core.dependencies import get_current_user
from ..models.user import User

router = APIRouter()

# Agora credentials - these should be set as environment variables
AGORA_APP_ID = os.getenv("AGORA_APP_ID", "88f1741521a941778d07e17a48890191")
AGORA_APP_CERTIFICATE = os.getenv("AGORA_APP_CERTIFICATE", "d0d7bfc5fd92445baa94588a770ef431")

class TokenRequest(BaseModel):
    channel_name: str
    uid: Optional[int] = 0
    role: Optional[str] = "publisher"  # publisher or attendee
    expiry_time: Optional[int] = 3600  # Token expiry in seconds (default: 1 hour)

class TokenResponse(BaseModel):
    token: str
    app_id: str
    channel_name: str
    uid: int
    expiry_time: int
    expires_at: int

@router.post("/generate-token", response_model=TokenResponse)
async def generate_agora_token(
    request: TokenRequest,
    current_user: User = Depends(get_current_user)
):
    """
    Generate a fresh Agora RTC token for video/audio calls
    
    Args:
        request: Token generation request containing channel name, uid, role, and expiry
        current_user: Authenticated user (ensures only logged-in users can generate tokens)
    
    Returns:
        TokenResponse: Generated token with metadata
    
    Raises:
        HTTPException: If Agora certificate is not configured or token generation fails
    """
    if not AGORA_APP_CERTIFICATE:
        raise HTTPException(
            status_code=500,
            detail="Agora App Certificate not configured. Please set AGORA_APP_CERTIFICATE environment variable."
        )
    
    try:
        # Calculate expiry timestamp
        current_timestamp = int(time.time())
        privilege_expired_ts = current_timestamp + request.expiry_time
        
        # Determine role
        role = Role_Publisher if request.role.lower() == "publisher" else Role_Attendee
        
        # Generate token
        token = RtcTokenBuilder.buildTokenWithUid(
            AGORA_APP_ID,
            AGORA_APP_CERTIFICATE, 
            request.channel_name,
            request.uid,
            role,
            privilege_expired_ts
        )
        
        return TokenResponse(
            token=token,
            app_id=AGORA_APP_ID,
            channel_name=request.channel_name,
            uid=request.uid,
            expiry_time=request.expiry_time,
            expires_at=privilege_expired_ts
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to generate Agora token: {str(e)}"
        )

@router.post("/refresh-token", response_model=TokenResponse)
async def refresh_agora_token(
    request: TokenRequest,
    current_user: User = Depends(get_current_user)
):
    """
    Refresh an existing Agora token with a new expiry time
    This is the same as generating a new token but with explicit refresh semantics
    """
    return await generate_agora_token(request, current_user)

class ChannelInfo(BaseModel):
    channel_name: str
    participant_count: int
    is_active: bool

@router.get("/channel/{channel_name}/info")
async def get_channel_info(
    channel_name: str,
    current_user: User = Depends(get_current_user)
) -> ChannelInfo:
    """
    Get information about an Agora channel
    Note: This is a placeholder - actual implementation would require Agora's RESTful API
    """
    # This would require implementing Agora's RESTful API calls
    # For now, return basic info
    return ChannelInfo(
        channel_name=channel_name,
        participant_count=0,  # Would need to query Agora's API
        is_active=False  # Would need to query Agora's API
    )

class StartCallRequest(BaseModel):
    chat_room_id: str
    call_type: str = "video"

class CallSession(BaseModel):
    session_id: str
    channel_name: str
    participants: list[str]
    call_type: str  # "video" or "voice"
    created_at: str
    status: str  # "active", "ended", "failed"

@router.post("/start-call")
async def start_call_session(
    request: StartCallRequest,
    current_user: User = Depends(get_current_user)
) -> CallSession:
    """
    Start a new call session for a chat room
    This creates a call session record and returns the channel information
    """
    import uuid
    from datetime import datetime
    
    # Generate unique session ID and channel name
    session_id = str(uuid.uuid4())
    channel_name = f"call_{request.chat_room_id}_{session_id[:8]}"
    
    # In a real implementation, you'd save this to your database
    call_session = CallSession(
        session_id=session_id,
        channel_name=channel_name,
        participants=[current_user.id], # Add current user as first participant
        call_type=request.call_type,
        created_at=datetime.utcnow().isoformat(),
        status="active"
    )
    
    return call_session

@router.post("/join-call/{session_id}")
async def join_call_session(
    session_id: str,
    current_user: User = Depends(get_current_user)
):
    """
    Join an existing call session
    Returns the channel name and generates a token for the user
    """
    # In a real implementation, you'd look up the call session from database
    # For now, reconstruct the channel name (this is a simplified approach)
    channel_name = f"call_session_{session_id}"
    
    # Generate token for the user to join
    token_request = TokenRequest(
        channel_name=channel_name,
        uid=int(current_user.id[:8], 16) if current_user.id else 0,  # Convert user ID to int
        role="publisher"
    )
    
    token_response = await generate_agora_token(token_request, current_user)
    
    return {
        "session_id": session_id,
        "channel_name": channel_name,
        "token_info": token_response
    }

@router.get("/health")
async def agora_health_check():
    """Health check for Agora service"""
    return {
        "status": "healthy",
        "agora_configured": bool(AGORA_APP_CERTIFICATE),
        "app_id": AGORA_APP_ID[:8] + "..." if AGORA_APP_ID else None
    }
