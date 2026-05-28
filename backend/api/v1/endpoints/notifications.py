import logging
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from datetime import datetime
from config.database import get_db
from database import models
from api.v1.endpoints.auth import get_current_user

logger = logging.getLogger(__name__)
router = APIRouter()

class NotificationSchema(BaseModel):
    id: str
    title: str
    body: str
    type: str  # 'arrival', 'saving', 'warning', 'summary'
    timestamp: datetime
    is_read: bool

@router.get("/", response_model=list[NotificationSchema])
def get_notifications(
    limit: int = 20,
    unread_only: bool = False,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Fetch notifications for the current user."""
    # TODO: Query Notification table when it's created
    # For now, return mock notifications
    mock_notifications = [
        {
            "id": "n1",
            "title": "Welcome back!",
            "body": "EcoMesh is optimizing Zone B for your arrival.",
            "type": "arrival",
            "timestamp": datetime.now(),
            "is_read": True,
        },
        {
            "id": "n2",
            "title": "Ghost Power Detected",
            "body": "Zone A has 3 unclaimed sockets drawing 42W.",
            "type": "warning",
            "timestamp": datetime.now(),
            "is_read": False,
        },
    ]
    return mock_notifications[:limit]

@router.get("/unread-count")
def get_unread_count(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get unread notification count for current user."""
    # TODO: Query Notification count when table is created
    return {"count": 2}

@router.post("/{notification_id}/read", status_code=200)
def mark_as_read(
    notification_id: str,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Mark a notification as read."""
    # TODO: Update Notification.is_read = True
    return {"status": "success", "message": f"Notification {notification_id} marked as read"}

@router.post("/read-all", status_code=200)
def mark_all_as_read(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Mark all notifications as read for current user."""
    # TODO: Update all Notification.is_read = True for user
    return {"status": "success", "message": "All notifications marked as read"}

@router.post("/{notification_id}/delete", status_code=200)
def delete_notification(
    notification_id: str,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Delete a notification."""
    # TODO: Delete Notification record
    return {"status": "success", "message": f"Notification {notification_id} deleted"}
