# README

### Getting Started
```shell
$ git clone git@github.com:desoleary/rails-light-service-redis-orm-boilerplate.git
$ cd rails-light-service-redis-orm-boilerplate
$ bundle install
$ bin/rspec
$ bin/rake rswag:specs:swaggerize # Optionally re-generates API Docs
$ brew install redis # Optional
$ redis-server # runs redis server on port 6379
$ bin/rails c # Ensure you have OS redis installed and running under port 6379
$ open http://0.0.0.0:3000/api-docs # opens Swagger API Docs
```

### API Docs
- URL: http://0.0.0.0:3000/api-docs
- Regenerate API: `bin/rake rswag:specs:swaggerize`

### Contracts
Introduced validation contracts via `dry-validation` library

### Models (Redis)
Introduced `ApplicationEntry` in order to simplify redis model storage interactions

### Services (Light Services)
Service layer introduced to promote re-use and focus on single responsibilities via action classes.

- `add_errors`
  - adds `errors to context` and returns immediately from current action
  - `organizer fails` the context to ensure all subsequent actions do not get called when `ctx[:errors]` is filled

