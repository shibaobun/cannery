# v0.9.1
- Code quality improvements

# v0.9.0
- Add length limits to all string fields
- Add selectable ammo types
- Improve onboarding experience slightly
- Remove show used view from a container since it doesn't really make that much
  sense

# v0.8.6
- Fix duplicate entries showing up
- Show ammo packs under a type in a table by default
- Only show historical ammo type information when displaying "Show used" in table
- Only show historical ammo pack information when displaying "Show used" in table
- Fix some values not being sorted in tables properly
- Code quality improvements
- Show link to ammo pack in ammo pack table while viewing ammo type

# v0.8.5
- Add link in readme to github mirror
- Fix tables unable to sort on empty dates
- Only show historical ammo type information when displaying "Show used"
- Fix even more accessibility issues

# v0.8.4
- Improve accessibility
- Code quality improvements
- Fix dead link of example bullet abbreviations
- Fix inaccurate error message when updating shot records
- Fix tables not sorting dates correctly
- Fix dates displaying incorrectly
- Fix container table not displaying all fields
- Fix textareas resizing when typing in them

# v0.8.3
- Improve some styles
- Improve server log
- Various minor improvements

# v0.8.2
- Fix bug with public registration
- Improve templates
- Improve invites, record usage
- Fix padding on more pages when using chrome
- Add oban metrics to server log and live dashboard

# v0.8.1
- Update dependencies
- Show topbar on form submit/page refresh
- Make loading/reconnection less intrusive
- Add QR code for invite link

# v0.8.0
- Add search to catalog, ammo, container, tag and range index pages
- Tweak urls for catalog, ammo, containers, tags and shot records
- Fix bug with shot group chart not drawing lines between days correctly
- Improve cards across app (make them line up with each other)
- Update translations and add spanish!!! (thank you Brea and Hannah!)

# v0.7.2
- Code improvements

# v0.7.1
- Fix table component alignment and styling
- Fix toggle button styling
- Miscellanous code improvements
- Improve container index table
- Fix bug with ammo not updating after deleting shot group
- Replace ammo "added on" with "purchased on"
- Miscellaneous wording improvements
- Update translations

# v0.7.0
- Add shading to table component
- Fix chart to sum by day
- Fix whitespace when copying invite url
- Make ammo type show page also display ammo groups as table
- Make container show page also display ammo groups as table
- Display CPR for ammo packs
- Add original count for ammo packs
- Add ammo pack CPR and original count to json export

# v0.6.0
- Update translations
- Display used-up date on used-up ammo
- Make ammo index page a bit more compact
- Make ammo index page filter used-up ammo
- Make ammo catalog page include ammo count
- Make ammo type show page a bit more compact
- Make ammo type show page include container names for each ammo
- Make ammo type show page filter used-up ammo
- Make container index page optionally display a table
- Make container show page a bit more compact
- Make container show page filter used-up ammo
- Forgot to add the logo as the favicon whoops
- Add graph to range page
- Add JSON export of data
- Add ammo cloning
- Add ammo type cloning
- Add container cloning
- Fix bug with moving ammo packs between containers
- Add button to set rounds left to 0 when creating a shot group
- Update project dependencies

# v0.5.4
- Rename "Ammo" tab to "Catalog", and "Manage" tab is now "Ammo"
- Ammo groups are now just referred to as Ammo or "Packs"
- URL paths now reflect new names
- Add pack and round count to container information
- Add cute logo >:3 Thank you [kalli](https://twitter.com/t0kkuro)!
- Add note about deleting an ammo type deleting all ammo of that type as well
- Prompt to create first ammo type before trying to create first ammo
- Add note about creating unlimited invites
- Update screenshot lol

# v0.5.3
- Update French translation: Thank you [duponin](https://udongein.xyz/users/duponin)!
- Update German translation: Thank you [Kaia](https://shitposter.club/users/kaia)!

# v0.5.2
- Add "Added on" date to ammo groups
- Add "Added on" date to ammo types
- Add "Registered on" date to user information
- Add language in user settings. The `LOCALE` environment variable will continue
  to set the default locale for the application.
- Add involvement links to home page
- Fix button text-wrapping
- Update dependencies

# v0.5.1
- Add French translation: Thank you [duponin](https://udongein.xyz/users/duponin)!

# v0.5.0
- Add German translation: Thank you [Kaia](https://shitposter.club/users/kaia)!
- Fix not being able to edit ammo group when fully used up
- Fix bug with average price per round calculation
- Show average price per round on ammo type table
- Use Elixir v1.13.4

# v0.4.1
- Fix button and tag text wrapping
- Code quality fixes

# v0.4.0
- Make tables sortable
- Add link to changelog from version number
- Fix some elements flashing with black background
- Fix bug with moving ammo group to new container
- Fix bug with no error showing up for create ammo group form

# v0.3.0
- Fix ammo type counts not showing when count is 0
- Add prompt to create first container before first ammo group
- Edit and delete shot groups from ammo group show page
- Use today's date when adding new shot groups
- Create multiple ammo groups at one time

# v0.2.3
- Fix modals with overflowing forms
- Fix grids having uneven margins in phone mode
- Add page titles to registration and setting pages

# v0.2.2
- Fix loading and reconnecting pages not being fixed
- Fix closing modal in some cases not triggering a page reload
- Fix error when display container and tag edit routes from a fresh reload

# v0.2.1
- Fix checkbox spacing for mobile view
- Fix spacing with form elements in mobile view
- Fix user card spacing

# v0.2.0
- Add or remove tags from containers list and details page
- Show tags on containers
- Add "Cannery" to page titles
- Don't show true/false column for ammo types if all values are false
- Fix ammo type firing type display
- Show original count, current value, and percentage remaining for ammo groups
- Show shot history for an ammo group
- Show ammo round totals and total shot for ammo types

# v0.1.0
- Initial release!
