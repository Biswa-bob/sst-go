Go/
├── main.go # app entrypoint
├── go.mod # Go module
├── go.sum # Go module checksums
├── README.md # project README
├── LICENSE # license
├── sst.config.ts # SST v3 configuration
├── docker-compose.yml # local dev services (DBs)
│
├── internal/ # private application code
│ ├── api/ # HTTP handlers
│ │ └── dummy.handler.go
│ ├── app/ # app wiring
│ │ └── app.go
│ ├── models/ # domain models
│ │ └── dummy_collection.go
│ ├── store/ # persistence layer
│ │ ├── database.go
│ │ └── dummy.store.go
│ ├── routes/ # route registrations
│ │ └── routes.go
│ ├── middleware/ # middlewares
│ ├── tokens/ # auth/token helpers
│ └── utils/ # utility helpers
│
├── migrations/ # DB migration SQL
│ └── fs.go
