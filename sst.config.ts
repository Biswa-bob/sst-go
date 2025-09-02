/// <reference path="./.sst/platform/config.d.ts" />

export default $config({
	app(input) {
		return {
			name: 'hello-world-api',
			removal: input?.stage === 'production' ? 'retain' : 'remove',
			home: 'aws',
			providers: {
				aws: {
					profile: 'personal',
				},
			},
		};
	},
	async run() {
		// Create a simple API using Go
		const api = new sst.aws.Function('HelloWorldAPI', {
			handler: './main.go',
			runtime: 'go',
			architecture: 'arm64',
			url: true,
			environment: {
				STAGE: $app.stage,
			},
		});

		return {
			api: api.url,
		};
	},
});
