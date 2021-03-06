console.log('## Welcome to Git Robot ##');

var Git = require("nodegit");
var path = require("path");

var argv = require('minimist')(process.argv.slice(2));
var repo = null;
if (argv.r) {
    console.dir(argv);
    repo = argv.r;
} else console.log('Usage: -r <repository>');


// Open the repository directory.
//Git.Repository.open(path.resolve(__dirname, "../../Projects/SauceLab/.git"))
if (repo)
  Git.Repository.open(path.resolve(__dirname, repo))
  // Open the master branch.
  .then(success = function (repo) {
      console.log('Repository ' + argv.r + ' opened successfully');
      repo.getBranch('octopack').then(function (ref) {
          console.log('Branch Name is ' + ref)
          return ref;
      }, function(err){
		  console.log('Branch NOT found..');
	  });

	repo.getTagByName('v0.0.1').then(function (ref) {
    console.log('Owner of Tag -> ' + ref.name() + ' is ' + ref.message()) 
         return ref;
    }, function (err) { console.log('Error getting TAG :' + err)});

     return repo.getMasterCommit();
  }, error = function (err) { console.log(err.message)})

  // Display information about commits on master.
  .then(function (firstCommitOnMaster) {
      // Create a new history event emitter.
      var history = firstCommitOnMaster.history();

      // Create a counter to only show up to 9 entries.
      var count = 0;

      // Listen for commit events from the history.
      history.on("commit", function (commit) {

          // Disregard commits past 9.
          if (++count >= 9) {
              return;
          }

          // Show the commit sha.
          //console.log("commit " + commit.sha());
          console.log("commit data " + commit);

          // Store the author object.
          //var author = commit.author();

          // Display author information.
          //console.log("Author:\t" + author.name() + " <" + author.email() + ">");

          // Show the commit date.
          //console.log("Date:\t" + commit.date());

          // Give some space and show the message.
          console.log("\n    " + commit.message());
      });

      // Start emitting events.
      history.start();
  });

/* sample code
var getMostRecentCommit = function (repository) {
    return repository.getBranchCommit("master");
};

var getCommitMessage = function (commit) {
    return commit.message();
};

Git.Repository.open(path.resolve(__dirname, "../Projects/SauceLab/.git"))
  .then(getMostRecentCommit)
  .then(getCommitMessage)
  .then(function (message) {
      console.log(message);
  });
*/

