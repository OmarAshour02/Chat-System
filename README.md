# Instabug Chat API

This is a Rails-based API for managing chat applications, chats, and messages. It uses Docker for easy setup and deployment.

## Prerequisites

- Docker
- Docker Compose

## Setting Up the Application

1. Clone the repository:
   ```
   git clone https://github.com/OmarAshour02/chat_system.git
   cd chat_system
   ```

2. Build the Docker images:
   ```
   docker-compose build
   ```

3. Create and set up the database:
   ```
   docker-compose run web /rails/bin/rails db:create db:migrate
   ```

## Running the Application

1. Start the application:
   ```
   docker-compose up
   ```

2. The API will be available at `http://localhost:3000`

## API Endpoints

### Applications

- Create a new application:
  ```
  POST /api/v1/applications
  ```

- Get application details:
  ```
  GET /api/v1/applications/:token
  ```

- Update an application:
  ```
  PUT /api/v1/applications/:token
  ```

### Chats

- Create a new chat:
  ```
  POST /api/v1/applications/:application_token/chats
  ```

- List all chats for an application:
  ```
  GET /api/v1/applications/:application_token/chats
  ```

- Get chat details:
  ```
  GET /api/v1/applications/:application_token/chats/:number
  ```

### Messages

- Create a new message:
  ```
  POST /api/v1/applications/:application_token/chats/:chat_number/messages
  ```

- List all messages in a chat:
  ```
  GET /api/v1/applications/:application_token/chats/:chat_number/messages
  ```

- Search messages:
  ```
  GET /api/v1/applications/:application_token/chats/:chat_number/messages/search?query=:query
  ```

## Additional Information

- The application uses MySQL for the database and Redis for background job processing.
- Sidekiq is used for handling background jobs.
- Elasticsearch is set up for full-text search capabilities.

## Troubleshooting

If you encounter any issues, please check the Docker logs:

```
docker-compose logs
```

For more specific logs:

```
docker-compose logs web
docker-compose logs sidekiq
```

## Contributing

Please read CONTRIBUTING.md for details on our code of conduct, and the process for submitting pull requests to us.

## License

This project is licensed under the MIT License - see the LICENSE.md file for details.
