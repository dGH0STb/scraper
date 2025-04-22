import { Callback, Context, Handler } from "aws-lambda";
import puppeteer from "puppeteer-extra";
import StealthPlugin from "puppeteer-extra-plugin-stealth";
import { Browser, Page } from "puppeteer";

interface ExampleEvent {
    url?: string;
    waitTime?: number;
}

export const handler: Handler = async (
    event: ExampleEvent,
    context: Context,
    callback: Callback
): Promise<any> => {
    let browser: Browser | null = null;

    try {
        console.log("Event received:", JSON.stringify(event));

        // Configure timeout to allow for proper cleanup
        context.callbackWaitsForEmptyEventLoop = false;

        // Add stealth plugin
        puppeteer.use(StealthPlugin());

        // URL to scrape (default or from event)
        const urlToScrape = event.url || "https://www.example.com";
        const waitTime = event.waitTime || 5000;

        console.log(`Preparing to scrape: ${urlToScrape}`);

        // AWS Lambda-compatible launch options
        const launchOptions = {
            headless: true,
            args: [
                "--no-sandbox",
                "--disable-setuid-sandbox",
                "--disable-dev-shm-usage",
                "--disable-gpu",
                "--single-process"
            ],
            ignoreHTTPSErrors: true
        };


        console.log("Launching browser...");
        browser = await puppeteer.launch(launchOptions);

        console.log("Creating new page...");
        const page: Page = await browser.newPage();

        // Set default timeout
        await page.setDefaultNavigationTimeout(30000);

        // Set user agent to avoid detection
        await page.setUserAgent(
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"
        );

        console.log(`Navigating to: ${urlToScrape}`);
        await page.goto(urlToScrape, { waitUntil: "networkidle2" });

        console.log(`Waiting for ${waitTime}ms...`);
        await new Promise((resolve) => setTimeout(resolve, waitTime));

        // Get page content
        const title = await page.title();
        const content = await page.content();

        console.log(`Page scraped: ${title}`);

        await browser.close();
        browser = null;

        // Return results
        const response = {
            statusCode: 200,
            title: title,
            url: urlToScrape,
            contentLength: content.length,
            // Only include a snippet of content to avoid huge response payloads
            contentSnippet: content.substring(0, 1000) + "..."
        };

        return response;
    } catch (error) {
        console.error("Error during web scraping:", error);

        // Ensure browser is closed in case of error
        if (browser) {
            try {
                await browser.close();
            } catch (closeError) {
                console.error("Error closing browser:", closeError);
            }
        }

        return {
            statusCode: 500,
            error: error instanceof Error ? error.message : "Unknown error",
            stack: error instanceof Error ? error.stack : undefined
        };
    }
};