/// <reference path="./.sst/platform/config.d.ts" />

export default $config({
	app(input) {
		return {
			name: 'hello-world-api',
			removal: input?.stage === 'production' ? 'retain' : 'remove',
			home: 'aws',
		};
	},
	async run() {
		// API Gateway REST API fronting the Go Lambda
		const api = new sst.aws.ApiGatewayV1('RestApi');

		api.route('ANY /', {
			handler: './main.go',
			runtime: 'go',
			architecture: 'arm64',
		});
		api.route('ANY /{proxy+}', {
			handler: './main.go',
			runtime: 'go',
			architecture: 'arm64',
		});

		api.deploy();

		return {
			api: api.url,
		};
	},
});
