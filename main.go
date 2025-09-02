package main

import (
	"context"
	"log"
	"net/http"
	"os"

	"hello-world-api/internal/app"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	chiadapter "github.com/awslabs/aws-lambda-go-api-proxy/chi"
)

var chiLambda *chiadapter.ChiLambda

func init() {
	log.Printf("Cold start - initializing application")

	// Initialize the application
	router := app.SetupRoutes()

	// Create the adapter for AWS Lambda
	chiLambda = chiadapter.New(router)
}

func Handler(ctx context.Context, req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	return chiLambda.ProxyWithContext(ctx, req)
}

func main() {
	// Check if running in AWS Lambda environment
	if os.Getenv("AWS_LAMBDA_RUNTIME_API") != "" {
		lambda.Start(Handler)
	} else {
		// Local development mode
		log.Printf("Starting server locally on :8080")
		router := app.SetupRoutes()
		log.Fatal(http.ListenAndServe(":8080", router))
	}
}
