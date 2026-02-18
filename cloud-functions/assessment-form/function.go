package assessmentform

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strings"

	"github.com/GoogleCloudPlatform/functions-framework-go/functions"
	"golang.org/x/oauth2/google"
	"google.golang.org/api/gmail/v1"
	"google.golang.org/api/option"
)

const (
	sendAsEmail = "info@awarenet.us"       // Gmail account used to send
	toEmail     = "tscheifler@awarenet.us" // Where submissions are delivered
)

func init() {
	functions.HTTP("AssessmentForm", AssessmentForm)
}

// FormSubmission holds the parsed form fields.
type FormSubmission struct {
	NeighborhoodName string `json:"neighborhood_name"`
	Zipcode          string `json:"zipcode"`
	NumHomes         string `json:"num_homes"`
	NumBusinesses    string `json:"num_businesses"`
	ContactMethod    string `json:"contact_method"`
	ContactValue     string `json:"contact_value"` // email address or phone number
}

// AssessmentForm is the HTTP Cloud Function entry point.
func AssessmentForm(w http.ResponseWriter, r *http.Request) {
	// CORS — allow requests from the sandbox site.
	// Update the origin below when going to production.
	w.Header().Set("Access-Control-Allow-Origin", "https://sandbox.awarenet.us")
	w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

	if r.Method == http.MethodOptions {
		// Preflight request — return immediately.
		w.WriteHeader(http.StatusNoContent)
		return
	}

	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var sub FormSubmission
	if err := json.NewDecoder(r.Body).Decode(&sub); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Basic validation.
	if strings.TrimSpace(sub.NeighborhoodName) == "" || strings.TrimSpace(sub.ContactValue) == "" {
		http.Error(w, "Missing required fields", http.StatusBadRequest)
		return
	}

	subject := "New Assessment Request — " + sub.NeighborhoodName

	body := fmt.Sprintf(`New assessment request received via sandbox.awarenet.us

Neighborhood/HOA Name : %s
Zipcode (primary)     : %s
Number of Homes       : %s
Number of Businesses  : %s
Contact Method        : %s
Contact               : %s
`,
		sub.NeighborhoodName,
		sub.Zipcode,
		sub.NumHomes,
		sub.NumBusinesses,
		sub.ContactMethod,
		sub.ContactValue,
	)

	if err := sendEmail(r.Context(), subject, body); err != nil {
		log.Printf("Error sending assessment email: %v", err)
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": "Failed to send submission. Please try again."})
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}

// sendEmail sends a plain-text email via the Gmail API using domain-wide delegation.
// The Cloud Function's service account must have the Gmail API scope and be granted
// domain-wide delegation authority to impersonate sendAsEmail.
func sendEmail(ctx context.Context, subject, body string) error {
	// FindDefaultCredentials uses the service account attached to the Cloud Function.
	creds, err := google.FindDefaultCredentials(ctx, gmail.GmailSendScope)
	if err != nil {
		return fmt.Errorf("finding credentials: %w", err)
	}

	// Impersonate the sendAsEmail account so the email appears to come from
	// info@awarenet.us rather than the raw service account address.
	// Requires domain-wide delegation enabled on the service account in the
	// Google Workspace admin console with scope:
	//   https://www.googleapis.com/auth/gmail.send
	tokenSrc := google.ImpersonateTokenSource(ctx, google.ImpersonateTokenConfig{
		TargetPrincipal: creds.JSON, // filled automatically via ADC
		Subject:         sendAsEmail,
		Scopes:          []string{gmail.GmailSendScope},
	})

	svc, err := gmail.NewService(ctx, option.WithTokenSource(tokenSrc))
	if err != nil {
		return fmt.Errorf("creating gmail service: %w", err)
	}

	raw := fmt.Sprintf(
		"From: %s\r\nTo: %s\r\nSubject: %s\r\nContent-Type: text/plain; charset=UTF-8\r\n\r\n%s",
		sendAsEmail, toEmail, subject, body,
	)
	encoded := base64.URLEncoding.EncodeToString([]byte(raw))

	_, err = svc.Users.Messages.Send("me", &gmail.Message{Raw: encoded}).Context(ctx).Do()
	if err != nil {
		return fmt.Errorf("sending gmail message: %w", err)
	}
	return nil
}
