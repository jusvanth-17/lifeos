"""
lifeOS FastAPI Backend
Main application entry point
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import uvicorn

from app.core.config import settings
from app.api.auth import router as auth_router
from app.api.users import router as users_router
from app.api.teams import router as teams_router
from app.api.projects import router as projects_router
from app.api.tasks import router as tasks_router
from app.api.chat import router as chat_router
from app.api.documents import router as documents_router
from app.api.ai import router as ai_router
from app.api.agora import router as agora_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager"""
    # Startup
    print("🚀 Starting lifeOS backend...")
    
    # Database initialization removed (Turso service removed)
    pass
    
    yield
    # Shutdown
    print("🛑 Shutting down lifeOS backend...")
    # Database cleanup removed (Turso service removed)


# Create FastAPI application
app = FastAPI(
    title="lifeOS API",
    description="A comprehensive team and personal productivity collaboration platform with integrated AI assistant",
    version="1.0.0",
    lifespan=lifespan,
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_HOSTS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API routers
app.include_router(auth_router, prefix="/api/v1/auth", tags=["authentication"])
app.include_router(users_router, prefix="/api/v1/users", tags=["users"])
app.include_router(teams_router, prefix="/api/v1/teams", tags=["teams"])
app.include_router(projects_router, prefix="/api/v1/projects", tags=["projects"])
app.include_router(tasks_router, prefix="/api/v1/tasks", tags=["tasks"])
app.include_router(chat_router, prefix="/api/v1/chat", tags=["chat"])
app.include_router(documents_router, prefix="/api/v1/documents", tags=["documents"])
app.include_router(ai_router, prefix="/api/v1/ai", tags=["ai"])
app.include_router(agora_router, prefix="/api/v1/agora", tags=["agora"])


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Welcome to lifeOS API",
        "version": "1.0.0",
        "status": "running"
    }


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy"}


if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )
