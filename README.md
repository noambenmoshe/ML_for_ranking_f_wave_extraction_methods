# Machine Learning for Ranking f-wave Extraction Methods in Single-Lead ECGs

## Overview

This repository contains MATLAB code and resources for the paper titled **"Machine Learning for Ranking f-wave Extraction Methods in Single-Lead ECGs"**. This research investigates various f-wave extraction methods for single-lead ECGs and utilizes machine learning to rank these methods based on their performance.

## Table of Contents

1. [Introduction](#introduction)
2. [Requirements](#requirements)
3. [Installation](#installation)
4. [Usage](#usage)
5. [Data](#data)
6. [Results](#results)
7. [Contributing](#contributing)
8. [License](#license)
9. [Contact](#contact)

## Introduction

The project includes MATLAB scripts for evaluating and ranking different f-wave extraction methods. The code calculates features from ECG data, evaluates four f-wave extraction methods, and applies a Random Forest model to determine the best-performing method.

## Requirements

To run the MATLAB code, you will need:

- MATLAB

## Installation

Clone the repository to your local machine:

```bash
git clone https://github.com/yourusername/yourrepository.git](https://github.com/noambenmoshe/fwave.git
cd fwave
```

## Usage

1. Data Preparation:
   Place your dataset in the databases/ directory. The dataset should be formatted according to the examples provided.

2. Running the Analysis:

Open MATLAB and navigate to the directory containing the cloned repository.
Run the main program script:
```bash
MAIN_PROGRAM
```
The MAIN_PROGRAM.m script includes an example of how to use the data and evaluate the four f-wave extraction methods. It calculates features for each ECG example and for each extraction method and saves them.
