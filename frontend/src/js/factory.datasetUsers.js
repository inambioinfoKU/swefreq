(function() {
    angular.module("App")
    .factory("DatasetUsers", ["$http", "$cookies", "$q", function($http, $cookies, $q) {
        $http.defaults.headers.post["Content-Type"] = "application/x-www-form-urlencoded";
        return {
            getUsers: getUsers,
            approveUser: approveUser,
            revokeUser: revokeUser,
            requestAccess: requestAccess,
        };

         function getUsers(dataset) {
            var defer = $q.defer();
            var data = {"pending": [], "current": []};
            $q.all([
                $http.get( "/api/datasets/" + dataset + "/users_pending" )
                    .then(function(d) {
                        data["pending"] = d.data.data;
                    }
                ),
                $http.get( "/api/datasets/" + dataset + "/users_current" )
                    .then(function(d) {
                        data["current"] = d.data.data;
                    }
                )
            ]).then(function(d) {
                defer.resolve(data);
            });
            return defer.promise;
        };

         function approveUser(dataset, email) {
            return $http.post(
                    "/api/datasets/" + dataset + "/users/" + email + "/approve",
                    $.param({"_xsrf": $cookies.get("_xsrf")})
                );
        };

         function revokeUser(dataset, email) {
            return $http.post(
                    "/api/datasets/" + dataset + "/users/" + email + "/revoke",
                    $.param({"_xsrf": $cookies.get("_xsrf")})
                )
        };

         function requestAccess(dataset, user) {
            return $http({url:"/api/datasets/" + dataset + "/users/" + user.email + "/request",
                   method:"POST",
                   data:$.param({
                           "email":       user.email,
                           "userName":    user.userName,
                           "affiliation": user.affiliation,
                           "country":     user.country["name"],
                           "_xsrf":       $cookies.get("_xsrf"),
                           "newsletter":  user.newsletter ? 1 : 0
                        })
                }
            );
        };
    }]);
})();