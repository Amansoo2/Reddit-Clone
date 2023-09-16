from flask import jsonify  #This allows us to handle the client-side data transfer a lot smoother. It easily converts python data structure into JSON format
from flask_login import current_user 
from functools import wraps
#Flask_login is an extension for Flask that provides user-session management and authentication functionalities.


def auth_role(role): #define a function that takes a role parameter
    def wrapper(func): #establish decorator function
        def decorated(*args, **kwargs): #This allows us to take in an arbitrary amount of arguments
            @wraps(func) #Allows us to preserve the original functions name
            if isinstance(role, list) == True: #This checks if role is a single value or list, if single value, converts to a list
                roles = role
            else:
                roles = [role]
            for r in roles: #Check if the current user has any of the roles
                if not any(current_user.has_role(r)):
                    return jsonify({"Warning": "You're Unathorized"}), 401 #If not, return unauthorized and a 401 HTTP status code

            return func(*args, **kwargs)

        return decorated
    
    return wrapper



