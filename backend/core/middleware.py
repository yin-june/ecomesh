import time
import logging
from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware

logger = logging.getLogger(__name__)

class ProcessTimeMiddleware(BaseHTTPMiddleware):
    """
    Measures endpoint latency. 
    Crucial for proving to judges that your AI inference and mesh routing 
    operate well within the <500ms latency target.
    """
    async def dispatch(self, request: Request, call_next):
        start_time = time.time()
        response = await call_next(request)
        process_time = time.time() - start_time
        
        # Add latency metric to the response headers
        response.headers["X-Process-Time-ms"] = str(round(process_time * 1000, 2))
        
        if process_time > 0.5:
            logger.warning(f"Latency spike on {request.url.path}: {process_time:.3f}s")
            
        return response