bash# Add to crontab for daily backups at 3 AM
crontab -e

# Add this line:
0 3 * * * cd /opt/content-empire && docker-compose run --rm backup

bash# Run a manual backup test (after Docker containers are running)

# Wait for all services to be ready, then test backup
docker-compose run --rm backup

# Check if backup was created
ls -la backups/