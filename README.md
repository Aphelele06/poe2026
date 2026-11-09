# Raceway

ASP.NET Core 8 MVC web app for managing running events. Roles: **Admin**, **Organiser**, **Participant**.
Event banner images are stored in **Azure Blob Storage**; the app can run in **Docker**.

## Prerequisites
- Visual Studio 2022+ (or .NET 8 SDK), SQL Server (LocalDB / SQL Express) or Docker Desktop
- An Azure Storage account with a container called `event-banners` (blob anonymous access enabled)
- Git / GitHub Desktop, SSMS (optional, to inspect the database)

## Run locally
```powershell
cd Race
# 1. Store the storage connection string OUTSIDE source control
dotnet user-secrets set "AzureStorage:ConnectionString" "<your storage account connection string>"

# 2. Create / update the database (first time: create the migration for the new Event tables)
dotnet ef migrations add AddEventsAndBannerImage
dotnet ef database update

# 3. Run
dotnet run
```
`appsettings.json` already contains `AzureStorage:ContainerName = event-banners`.
The app also applies pending migrations on start-up and seeds the three roles and an admin user.

## Run with Docker (single command)
```powershell
copy .env.example .env      # then edit .env (SA_PASSWORD + AZURE_STORAGE_CONNECTION_STRING)
docker compose up --build
```
Open <http://localhost:8080>. This starts the MVC app **and** a SQL Server container.

Without compose (database must be reachable from the container, e.g. SQL Server on the host):
```powershell
docker build -t raceway-mvc .
docker run -p 8080:8080 `
  -e "ConnectionStrings__DefaultConnection=Server=host.docker.internal,1433;Database=RaceDB;User Id=sa;Password=<password>;TrustServerCertificate=True" `
  -e "AzureStorage__ConnectionString=<storage connection string>" `
  raceway-mvc
```
> LocalDB and `Trusted_Connection=True` do not work inside a Linux container - use SQL authentication.

## Features added in this iteration
- `Event` gets `BannerImageUrl` and `BannerBlobName`; Category, Enrolment and Result models
- `IBlobStorageService` / `BlobStorageService` (validate, upload, delete) using Azure.Storage.Blobs
- `EventsController`: list, details, create, edit, delete with banner upload / replace / remove
- Event views (`Index`, `Details`, `Create`, `Edit`, `Delete`, `_EventForm`) and `_Alerts`
- Role-aware navigation, Dockerfile, docker-compose.yml

## Roles
| Role | Can do |
|---|---|
| Admin | Manage users and roles, see and manage all events |
| Organiser | Create, edit and delete their own events and banners |
| Participant | Browse events and view event details |

## Security notes
Never commit storage keys, `.env`, or `secrets.json`. If a key was ever shown on screen or in a recording, regenerate it in
Azure Portal > Storage account > Access keys > Rotate key.
