/**
 * Seed storage and DB with example review
 * Run after: supabase db reset
 *
 * deno run --allow-net --allow-read --allow-env --env=supabase/functions/tests/.env supabase/functions/tests/seed-storage.ts
 */
import { createClient } from "@supabase/supabase-js";

const SUPABASE_URL = "http://127.0.0.1:54321";
const SECRET_KEY = Deno.env.get("SUPABASE_SECRET_KEY");
if (!SECRET_KEY) throw new Error("SUPABASE_SECRET_KEY not set");

const USER_ID = "a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d";
const REVIEW_ID = "b2c3d4e5-f6a7-4b8c-9d0e-1f2a3b4c5d6e";
const EXAMPLE_DIR = "./example_review";
const PDF_FILENAME = "s12893-023-02108-1.pdf";

const supabase = createClient(SUPABASE_URL, SECRET_KEY);

// 1. Create review record
console.log("Creating review...");
const { error: reviewError } = await supabase.from("reviews").insert({
	id: REVIEW_ID,
	user_id: USER_ID,
	title: "Test Systematic Review",
});
if (reviewError) throw reviewError;

// 2. Upload PDF
console.log("Uploading PDF...");
const pdfPath = `${USER_ID}/${REVIEW_ID}/${PDF_FILENAME}`;
const pdf = await Deno.readFile(`${EXAMPLE_DIR}/${PDF_FILENAME}`);
const { error: pdfError } = await supabase.storage
	.from("reviews")
	.upload(pdfPath, pdf, { contentType: "application/pdf" });
if (pdfError) console.error("PDF upload failed:", pdfError.message);

// Update review with pdf_path
await supabase
	.from("reviews")
	.update({ pdf_path: pdfPath })
	.eq("id", REVIEW_ID);

// 3. Upload pages and create records
console.log("Uploading pages...");
for (let i = 1; i <= 18; i++) {
	const fileName = `page-${i}.png`;
	const storagePath = `${USER_ID}/${REVIEW_ID}/pages/page_${i}.png`;

	const file = await Deno.readFile(`${EXAMPLE_DIR}/${fileName}`);
	const { error: uploadError } = await supabase.storage
		.from("reviews")
		.upload(storagePath, file, { contentType: "image/png" });

	if (uploadError) {
		console.error(`Upload failed: ${fileName}`, uploadError.message);
		continue;
	}

	const { error: insertError } = await supabase.from("review_pages").insert({
		review_id: REVIEW_ID,
		page_number: i,
		image_path: storagePath,
	});

	if (insertError)
		console.error(`Insert failed: page ${i}`, insertError.message);
	else console.log(`Done: page ${i}`);
}

console.log("Seed complete!");
