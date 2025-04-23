import { handler } from "./index";

const mockContext: any = {
    callbackWaitsForEmptyEventLoop: true,
    functionName: "local-test",
    getRemainingTimeInMillis: () => 30000,
};

const mockCallback = (error: any, result: any) => {
    if (error) {
        console.error("Error:", error);
    } else {
        console.log("Result:", result);
    }
};

const testEvent = {
    url: "https://github.com",
    waitTime: 5000
};

console.log("Starting local test...");
(async () => {
    try {
        const result = await handler(testEvent, mockContext, mockCallback);
        console.log("Test completed successfully:", result);
    } catch (error) {
        console.error("Test failed:", error);
    }
})();