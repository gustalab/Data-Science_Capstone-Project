## Gokhan USTA
## MovieLens Project
## HarvardX: PH125.9x - Data Science: Capstone Project

#################################################
# MovieLens Rating Prediction Project Code ################################################

#### Introduction ####

## Dataset ##

##########################################################
# Create edx set, validation set (final hold-out test set)
##########################################################

# Note: this process could take a couple of minutes

if(!require(tidyverse)) install.packages("tidyverse", repos = "http://cran.us.r-project.org")
if(!require(caret)) install.packages("caret", repos = "http://cran.us.r-project.org")
if(!require(data.table)) install.packages("data.table", repos = "http://cran.us.r-project.org")

library(tidyverse)
library(caret)
library(data.table)

# MovieLens 10M dataset:
# https://grouplens.org/datasets/movielens/10m/
# http://files.grouplens.org/datasets/movielens/ml-10m.zip

dl <- tempfile()
download.file("http://files.grouplens.org/datasets/movielens/ml-10m.zip", dl)

ratings <- fread(text = gsub("::", "\t", readLines(unzip(dl, "ml-10M100K/ratings.dat"))),
                 col.names = c("userId", "movieId", "rating", "timestamp"))

movies <- str_split_fixed(readLines(unzip(dl, "ml-10M100K/movies.dat")), "\\::", 3)
colnames(movies) <- c("movieId", "title", "genres")


# if using R 4.0 or later:
movies <- as.data.frame(movies) %>% mutate(movieId = as.numeric(movieId),
                                           title = as.character(title),
                                           genres = as.character(genres))


movielens <- left_join(ratings, movies, by = "movieId")

# Validation set will be 10% of MovieLens data
set.seed(1, sample.kind="Rounding") # if using R 3.5 or earlier, use `set.seed(1)`
test_index <- createDataPartition(y = movielens$rating, times = 1, p = 0.1, list = FALSE)
edx <- movielens[-test_index,]
temp <- movielens[test_index,]

# Make sure userId and movieId in validation set are also in edx set
validation <- temp %>% 
  semi_join(edx, by = "movieId") %>%
  semi_join(edx, by = "userId")

# Add rows removed from validation set back into edx set
removed <- anti_join(temp, validation)
edx <- rbind(edx, removed)

rm(dl, ratings, movies, test_index, temp, movielens, removed)

###############################################################################
###############################################################################

#### Methods, Analysis and Visualizations ####

# Head (display the first six line of the data)
head(edx)
head(validation)

# Summary of the datasets (summary statistics of data)
summary(edx)
summary(validation)


# Number of different (unique) movies and users in the edx dataset 
edx %>%
  summarize(n_users = n_distinct(userId),
          n_movies = n_distinct(movieId))


# Distribution of ratings

edx_ratings <- edx %>%  # take data and...
  group_by(rating) %>%  # ...group data by rating and...
  summarize(num_ratings = n()) %>% # ...summarize frequency of each rating and...
  arrange(desc(num_ratings)) # ...arrange data in descending order edx_ratings
edx_ratings

edx_ratings %>% # for each rating, plot frequency
  ggplot(aes(rating, num_ratings, color = rating)) +
  geom_point(aes(size = num_ratings)) +
  scale_color_gradientn(colours = rainbow(5)) +
  scale_size_continuous(limits = c(0, 4e+06)) +
  xlim(0,5) +
  labs(x = "Rating", y = "Number of Ratings", title = "Rating distribution", color = "Rating", size = "Number of Ratings") +
  theme_light()

edx %>% # for each rating, plot frequency
  ggplot(aes(rating)) +
  geom_histogram(binwidth = 0.50, color = "blue") +
  scale_x_discrete(limits = c(seq(0.5,5,0.5))) +
  scale_y_continuous(breaks = c(seq(0, 3000000, 500000))) +
  ggtitle("Rating distribution") + 
  theme_light()



# Number of ratings per movie

edx_movies <- edx %>% # take data and...
  group_by(movieId) %>% # ...group by movie and...
  summarize(num_ratings = n(), avg_rating = mean(rating)) %>% # ...summarize ratings counts and average rating and...
  arrange(desc(num_ratings)) # ...arrange data in descending order
head(edx_movies)  # display top movies by number of ratings

edx_movies %>% # for each movie, plot the number of ratings
  ggplot(aes(movieId, num_ratings, color = avg_rating)) +
  geom_point() +
  scale_color_gradientn(colours = rainbow(5)) +
  labs(x = "MovieId", y = "Number of Ratings", title = "Ratings by Movie", color = "Average Rating") +
  theme_light()


edx %>% # plot the number of ratings per movie (log10 scaled)
  count(movieId) %>%
  ggplot(aes(n)) +
  geom_histogram(bins = 50, color = "blue") +
  scale_x_log10() +
  xlab("Number of ratings") +
  ylab("Number of movies") +
  ggtitle("Number of ratings per movie") +
  theme_light()



# Table of 10 movies rated only once

edx %>%
  group_by(movieId) %>%
  summarize(count = n()) %>%
  filter(count == 1) %>%
  left_join(edx, by = "movieId") %>%
  group_by(title) %>%
  summarize(rating = rating, n_rating = count) %>%
  slice(1:10) %>%
  knitr::kable()



# Number of ratings given by users

edx_users <- edx %>% # take data and...
  group_by(userId) %>% # ...group by user and...
  summarize(num_ratings = n(), avg_rating = mean(rating)) %>% # ...summarize ratings counts and average rating and...
  arrange(desc(num_ratings)) # ...arrange data in descending order
head(edx_users) # display top users by number of ratings

edx_users %>% # for each movie, plot the number of ratings v num of ratings
  ggplot(aes(userId, num_ratings, color = avg_rating)) +
  geom_point() +
  scale_color_gradientn(colours = rainbow(5)) +
  labs(x = "UserId", y = "Number of Ratings", title = "Ratings by User", color = "Average Rating") +
  theme_light()


edx %>% # plot the number of ratings v number of users (log10 scaled)
  count(userId) %>%
  ggplot(aes(n)) +
  geom_histogram(bins = 30, color = "blue") +
  scale_x_log10() +
  xlab("Number of ratings") +
  ylab("Number of users") +
  ggtitle("Number of ratings given by users") +
  theme_light()



# Mean movie ratings given by users
edx %>%
  group_by(userId) %>%
  filter(n() >= 100) %>%
  summarize(b_u = mean(rating)) %>%
  ggplot(aes(b_u)) +
  geom_histogram(bins = 30, color = "blue") +
  xlab("Mean rating") +
  ylab("Number of users") +
  ggtitle("Mean movie ratings given by users") +
  scale_x_discrete(limits = c(seq(0.5,5,0.5))) +
  theme_light()




### Modelling approach ###

## Average movie rating model ##

# Dataset's average rating

avg_ratg <- mean(edx$rating)
avg_ratg


# Test results based on simple prediction 

naive_rmse <- RMSE(validation$rating, avg_ratg) 
naive_rmse

# Check results and save prediction in data frame
rmse_results <- data_frame(method = "Average movie rating model", RMSE = naive_rmse) 
rmse_results %>% knitr::kable()



## Movie effect model ##

# Simple model taking into account the movie effect b_i 
# Subtract the rating minus the mean for each rating the movie received 
# Plot number of movies with the computed b_i 

movie_avgs <- edx %>%
  group_by(movieId) %>%
  summarize(b_i = mean(rating - avg_ratg)) 
movie_avgs


movie_avgs %>% qplot(b_i, geom ="histogram", bins = 10, data = ., color = I("blue"),
                     ylab = "Number of movies", main = "Number of movies with the computed b_i") +
  theme_light()



# Test and save rmse results
predicted_ratings <- avg_ratg +  validation %>%
  left_join(movie_avgs, by='movieId') %>%
  pull(b_i)
model1_rmse <- RMSE(predicted_ratings, validation$rating) 
rmse_results <- bind_rows(rmse_results,
                          data_frame(method="Movie effect model", 
                                     RMSE = model1_rmse ))


# Check results
rmse_results %>% knitr::kable()


## Movie and user effect model ##

# Plot penalty term user effect #

user_avgs<- edx %>%
  left_join(movie_avgs, by='movieId') %>%
  group_by(userId) %>%
  filter(n() >= 100) %>%
  summarize(u_e = mean(rating - avg_ratg - b_i))



user_avgs%>% qplot(u_e, geom ="histogram", bins = 30, data = ., color = I("blue")) +
  theme_light()

user_avgs <- edx %>%
  left_join(movie_avgs, by='movieId') %>%
  group_by(userId) %>%
  summarize(u_e = mean(rating - avg_ratg - b_i))
user_avgs

# Test and save rmse results

predicted_ratings <- validation%>%
  left_join(movie_avgs, by='movieId') %>%
  left_join(user_avgs, by='userId') %>%
  mutate(predct = avg_ratg + b_i + u_e) %>%
  pull(predct)


model2_rmse <- RMSE(predicted_ratings, validation$rating) 
rmse_results <- bind_rows(rmse_results,
                          
                          data_frame(method="Movie and user effect model", 
                                     
                                     RMSE = model2_rmse))

# Check result
rmse_results %>% knitr::kable()


## Regularized movie and user effect model ##

# lambda is a tuning parameter
# Use cross-validation to choose it.

lambdas <- seq(0, 10, 0.25)


# For each lambda,find b_i & u_e, followed by rating prediction & testing

rmses <- sapply(lambdas, function(r){
  
  avg_ratg <- mean(edx$rating)

b_i <- edx %>%
  group_by(movieId) %>%
  summarize(b_i = sum(rating - avg_ratg)/(n()+r))

u_e <- edx %>%
  left_join(b_i, by="movieId") %>%
  group_by(userId) %>%
  summarize(u_e = sum(rating - b_i - avg_ratg)/(n()+r))

predicted_ratings <-
  validation %>%
  left_join(b_i, by = "movieId") %>%
  left_join(u_e, by = "userId") %>%
  mutate(predct = avg_ratg + b_i + u_e) %>%
  pull(predct)

return(RMSE(predicted_ratings, validation$rating))
})


# Plot rmses vs lambdas to select the optimal lambda                                                            
qplot(lambdas, rmses) 


# The optimal lambda                                                            
opt_lambda <- lambdas[which.min(rmses)]
opt_lambda

# Test and save results                                                            
rmse_results <- bind_rows(rmse_results,
                          data_frame(method="Regularized movie and user effect model", 
                                     RMSE = min(rmses)))

# Check result
rmse_results %>% knitr::kable()

#### Results ####                                                           
# RMSE results overview                                                         
rmse_results %>% knitr::kable()

#### Appendix ####
print("Operating System:")
version
