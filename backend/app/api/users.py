"""
User management API endpoints
"""

from fastapi import APIRouter, HTTPException, status

router = APIRouter()


@router.get("/me")
async def get_current_user():
    """Get current user profile"""
    # TODO: Implement user profile retrieval
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="User profile not implemented yet"
    )


@router.put("/me")
async def update_current_user():
    """Update current user profile"""
    # TODO: Implement user profile update
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="User profile update not implemented yet"
    )
