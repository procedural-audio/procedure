import subprocess
import json
import platform
import requests
import zipfile
import os
import shutil

BUILD_PATH = "build/"
FRAMEWORK_PATH = BUILD_PATH + "framework/"
JUCE_PATH = BUILD_PATH + "juce/"

def get_framework_revision() -> str:
    try:
        # Run the 'flutter --version --machine' command
        result = subprocess.run(
            ['flutter', '--version', '--machine'],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )

        # Check if the command was successful
        if result.returncode != 0:
            print(f"Error: {result.stderr}")
            return

        # Parse the JSON output
        flutter_info = json.loads(result.stdout)

        # Extract and print the frameworkRevision
        framework_revision = flutter_info.get('engineRevision')
        if framework_revision:
            return framework_revision
        else:
            print("Error: 'frameworkRevision' not found in the output.")

    except FileNotFoundError:
        print("Error: 'flutter' command not found. Make sure Flutter is installed and added to your PATH.")
    except json.JSONDecodeError:
        print("Error: Failed to parse JSON output from the 'flutter' command.")

def extract_zip_preserve_symlinks(zip_path, extract_to):
    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        for zip_info in zip_ref.infolist():
            file_path = os.path.join(extract_to, zip_info.filename)
            # Normalize the path (removes trailing slashes)
            file_path = os.path.normpath(file_path)

            # Check if the file is a symbolic link
            is_symlink = (zip_info.external_attr >> 16) & 0o120000 == 0o120000
            if is_symlink:
                # Read the symlink target
                with zip_ref.open(zip_info) as symlink_file:
                    target = symlink_file.read().decode('utf-8')

                # Ensure the parent directory exists
                os.makedirs(os.path.dirname(file_path), exist_ok=True)

                # Create the symlink
                os.symlink(target, file_path)
            else:
                # For directories
                if zip_info.is_dir():
                    os.makedirs(file_path, exist_ok=True)
                else:
                    # For regular files, ensure the directory exists
                    os.makedirs(os.path.dirname(file_path), exist_ok=True)
                    with zip_ref.open(zip_info) as source, open(file_path, 'wb') as target_file:
                        target_file.write(source.read())


def download_framework(output_dir, revision):
    url = f"https://storage.googleapis.com/flutter_infra_release/flutter/{revision}/darwin-x64/FlutterEmbedder.framework.zip"
    try:
        # Download the zip file
        print(f"Downloading from {url}...")
        response = requests.get(url)
        response.raise_for_status()

        # Save the zip file locally
        zip_path = "downloaded_file.zip"
        with open(zip_path, "wb") as file:
            file.write(response.content)
        print(f"Downloaded zip file saved as {zip_path}")

        extract_zip_preserve_symlinks(zip_path, output_dir)
        # Extract the zip file
        #with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        #    zip_ref.extractall(output_dir)
        #print(f"Extracted files to {output_dir}")

        # Clean up the zip file
        os.remove(zip_path)
        print("Temporary zip file removed.")

    except requests.RequestException as e:
        print(f"Error downloading the file: {e}")
    except zipfile.BadZipFile:
        print("Error: The downloaded file is not a valid zip file.")

def initialize_framework(path):
    revision = get_framework_revision()
    info_plist_path = os.path.join(path, "Versions/A/Resources/Info.plist")
    if os.path.exists(info_plist_path):
        with open(info_plist_path, "r") as plist_file:
            content = plist_file.read()
            if revision in content:
                print("Flutter framework artifacts found")
                return
    download_framework(path, revision)

def initialize_juce(juce_folder_path):
    juce_repo_url = "https://github.com/juce-framework/JUCE"

    if not os.path.exists(juce_folder_path):
        print(f"JUCE repository not found in {juce_folder_path}. Cloning...")
        try:
            subprocess.run([
                "git", "clone", "--recurse-submodules", juce_repo_url, juce_folder_path
            ], check=True)
            print(f"Successfully cloned JUCE into {juce_folder_path}")
        except subprocess.CalledProcessError as e:
            print(f"Error cloning JUCE: {e}")
    else:
        print(f"JUCE repository found")

def build_host(build_folder, host_source_folder, framework_folder):
    try:
        # Ensure JUCE is present in the build folder
        initialize_juce(build_folder + "juce")

        # Ensure the flutter framework is present in the build folder
        initialize_framework(build_folder + "framework")

        # Expand JUCE_PATH to a full path
        juce_dir_full_path = os.path.abspath(os.path.join(build_folder, "juce"))

        # Expand FRAMEWORK_PATH to a full path
        framework_dir_full_path = os.path.abspath(os.path.join(build_folder, "framework"))

        # Set up CMake build
        cmake_build_dir = os.path.join(build_folder, "host")
        os.makedirs(cmake_build_dir, exist_ok=True)

        # Configure the build
        subprocess.run([
            "cmake",
            "-B", cmake_build_dir,
            "-S", host_source_folder,
            f"-DJUCE_PATH={juce_dir_full_path}",
            f"-DFRAMEWORK_PATH={framework_dir_full_path}",
        ], check=True)

        # Build the project
        subprocess.run(["cmake", "--build", cmake_build_dir], check=True)
        print("JUCE component built successfully.")

    except subprocess.CalledProcessError as e:
        print(f"Error building JUCE component: {e}")

def build_app(build_folder):
    build_host(build_folder, "host", "framework")

    source_app = build_folder + "host/macos/standalone/NodusStandalone_artefacts/NodusStandalone.app"
    package_path = build_folder + "package"
    destination_app = os.path.join(package_path, "NodusStandalone.app")

    source_framework = build_folder + "framework"
    destination_framework = source_app + "/Contents/Frameworks/FlutterEmbedder.framework"

    os.makedirs(package_path, exist_ok=True)

    if os.path.exists(destination_app):
        shutil.rmtree(destination_app)

    shutil.copytree(source_app, destination_app)

    if os.path.exists(destination_framework):
        shutil.rmtree(destination_framework)

    print(source_framework)
    print(destination_framework)
    shutil.copytree(source_framework, destination_framework)

if __name__ == "__main__":
    build_app("build/")

    system_os = platform.system()
    print(system_os)

