"""
Authentication API endpoints
"""

from fastapi import APIRouter, HTTPException, status, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel
from typing import Dict, Any

from app.services.auth_service import auth_service
from app.models.user import User

router = APIRouter()
security = HTTPBearer()


# Request/Response Models
class RegisterRequest(BaseModel):
    email: str
    display_name: str


class RegisterResponse(BaseModel):
    message: str
    user_id: str


class WebAuthnRegistrationStartRequest(BaseModel):
    user_id: str
    email: str
    display_name: str


class WebAuthnRegistrationCompleteRequest(BaseModel):
    user_id: str
    credential: Dict[str, Any]


class WebAuthnAuthenticationStartRequest(BaseModel):
    email: str


class WebAuthnAuthenticationCompleteRequest(BaseModel):
    email: str
    credential: Dict[str, Any]


class LoginResponse(BaseModel):
    access_token: str
    token_type: str
    user_id: str


# Dependency to get current user
async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)) -> User:
    """Get current authenticated user"""
    user = await auth_service.get_current_user(credentials.credentials)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return user


# Authentication Endpoints
@router.post("/register", response_model=RegisterResponse)
async def register(request: RegisterRequest):
    """User registration endpoint"""
    try:
        # Create user
        user = await auth_service.create_user(
            email=request.email,
            display_name=request.display_name
        )
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User already exists or registration failed"
            )
        
        return RegisterResponse(
            message="User registered successfully. Please set up WebAuthn authentication.",
            user_id=user.id
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Registration failed: {str(e)}"
        )


@router.post("/webauthn/registration/start")
async def start_webauthn_registration(request: WebAuthnRegistrationStartRequest):
    """Start WebAuthn registration process"""
    try:
        options = await auth_service.start_webauthn_registration(
            user_id=request.user_id,
            email=request.email,
            display_name=request.display_name
        )
        
        if not options:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to start WebAuthn registration"
            )
        
        return options
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"WebAuthn registration start failed: {str(e)}"
        )


@router.post("/webauthn/registration/complete")
async def complete_webauthn_registration(request: WebAuthnRegistrationCompleteRequest):
    """Complete WebAuthn registration process"""
    try:
        success = await auth_service.complete_webauthn_registration(
            user_id=request.user_id,
            credential_data=request.credential
        )
        
        if not success:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="WebAuthn registration verification failed"
            )
        
        return {"message": "WebAuthn registration completed successfully"}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"WebAuthn registration completion failed: {str(e)}"
        )


@router.post("/webauthn/authentication/start")
async def start_webauthn_authentication(request: WebAuthnAuthenticationStartRequest):
    """Start WebAuthn authentication process"""
    try:
        options = await auth_service.start_webauthn_authentication(
            email=request.email
        )
        
        if not options:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found or no WebAuthn credentials registered"
            )
        
        return options
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"WebAuthn authentication start failed: {str(e)}"
        )


@router.post("/webauthn/authentication/complete", response_model=LoginResponse)
async def complete_webauthn_authentication(request: WebAuthnAuthenticationCompleteRequest):
    """Complete WebAuthn authentication process"""
    try:
        access_token = await auth_service.complete_webauthn_authentication(
            email=request.email,
            credential_data=request.credential
        )
        
        if not access_token:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="WebAuthn authentication verification failed"
            )
        
        # Get user to return user_id
        user_data = await auth_service.get_current_user(access_token)
        
        return LoginResponse(
            access_token=access_token,
            token_type="bearer",
            user_id=user_data.id if user_data else ""
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"WebAuthn authentication completion failed: {str(e)}"
        )


@router.post("/logout")
async def logout():
    """User logout endpoint"""
    # For JWT tokens, logout is typically handled client-side by discarding the token
    # In a production system, you might want to maintain a blacklist of revoked tokens
    return {"message": "Logged out successfully"}


@router.get("/me")
async def get_current_user_info(current_user: User = Depends(get_current_user)):
    """Get current user information"""
    return {
        "user_id": current_user.id,
        "email": current_user.email,
        "profile": current_user.profile.dict() if current_user.profile else None
    }
