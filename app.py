from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import os
import subprocess
import whisper
from transformers import pipeline
import glob
from urllib.parse import urlparse

# Initialize FastAPI app
app = FastAPI()

# Add CORS middleware to allow frontend communication
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Change this to specific domains in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Update yt-dlp path if necessary
yt_dlp_path = r"C:\yt-dlp\yt-dlp.exe"

# Request model for YouTube URL
class VideoRequest(BaseModel):
    url: str

# Storage for results (temporary)
transcripts = {}
summaries = {}

# Function to clean YouTube URLs
def clean_youtube_url(url):
    parsed_url = urlparse(url)
    clean_url = f"{parsed_url.scheme}://{parsed_url.netloc}{parsed_url.path}"
    return clean_url

# Function to download audio
def download_audio(url, output_path="YoutubeAudios"):
    os.makedirs(output_path, exist_ok=True)
    output_template = os.path.join(output_path, "%(title)s.%(ext)s").replace("\\", "/")
    command = f'"{yt_dlp_path}" -x --audio-format mp3 -o "{output_template}" "{url}"'

    try:
        subprocess.run(command, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except subprocess.CalledProcessError as e:
        print(f"❌ Error running yt-dlp: {e}")
        return None

    mp3_files = glob.glob(os.path.join(output_path, "*.mp3"))
    return max(mp3_files, key=os.path.getctime) if mp3_files else None

# Function to transcribe audio
def transcribe_audio(audio_path):
    print("🔍 Transcribing audio...")
    model = whisper.load_model("base")
    result = model.transcribe(audio_path)
    return result["text"].strip() if result["text"] else None

# Function to summarize text
def summarize_text(text):
    summarizer = pipeline("summarization", model="facebook/bart-large-cnn")

    # ✅ Truncate input text if it exceeds the model's token limit
    words = text.split()
    max_words = 500  # Adjust this as needed
    if len(words) > max_words:
        text = " ".join(words[:max_words])  # Use only the first 500 words

    summary = summarizer(text, max_length=150, min_length=50, do_sample=False)[0]['summary_text']
    return summary

# API: Root endpoint
@app.get("/")
def read_root():
    return {"message": "Hello, FastAPI!"}

# API: Process video (download, transcribe, summarize)
@app.post("/process")
async def process_video(request: VideoRequest):
    url = clean_youtube_url(request.url)
    print(f"🔍 Received request to process: {url}")

    # Download audio
    audio_path = download_audio(url)
    if not audio_path:
        raise HTTPException(status_code=500, detail="Failed to download audio")

    # Transcribe audio
    transcript = transcribe_audio(audio_path)
    if not transcript:
        raise HTTPException(status_code=500, detail="Failed to transcribe audio")

    # Summarize transcript
    summary = summarize_text(transcript)

    # Store results
    transcripts[url] = transcript
    summaries[url] = summary

    return {"message": "Processing complete", "url": url}

# API: Get transcript
@app.get("/transcript")
async def get_transcript(url: str):
    url = clean_youtube_url(url)
    if url in transcripts:
        return {"transcript": transcripts[url]}
    raise HTTPException(status_code=404, detail="Transcript not found")

# API: Get summary
@app.get("/summary")
async def get_summary(url: str):
    url = clean_youtube_url(url)
    if url in summaries:
        return {"summary": summaries[url]}
    raise HTTPException(status_code=404, detail="Summary not found")
